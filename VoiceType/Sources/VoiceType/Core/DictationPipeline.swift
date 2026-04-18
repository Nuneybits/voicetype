import Foundation
import AppKit
import AVFoundation
import WhisperKit

@MainActor
final class DictationPipeline: ObservableObject {
    var appState: AppState
    let hotkeyManager: HotkeyManager
    let audioCapture: AudioCapture
    let transcriptionEngine: TranscriptionEngine
    let historyStore: HistoryStore
    var modelManager: ModelManager
    let notepadController: NotepadPanelController
    let settings: UserSettings

    private var levelTimer: Task<Void, Never>?
    private var transcribeTimer: Task<Void, Never>?

    init(settings: UserSettings) {
        self.appState = AppState()
        self.hotkeyManager = HotkeyManager()
        self.audioCapture = AudioCapture()
        self.modelManager = ModelManager()
        self.transcriptionEngine = TranscriptionEngine(modelManager: modelManager)
        self.historyStore = HistoryStore()
        self.notepadController = NotepadPanelController()
        self.settings = settings

        hotkeyManager.onRecordingStart = { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }

        hotkeyManager.onRecordingStop = { [weak self] in
            Task { @MainActor in
                await self?.stopRecordingAndTranscribe()
            }
        }

        hotkeyManager.setup()

        notepadController.setup(
            appState: appState,
            modelManager: modelManager,
            onToggleRecording: { [weak self] in
                Task { @MainActor in
                    self?.toggleRecording()
                }
            },
            onCopyAll: { [weak self] in
                self?.copyAllText()
            },
            onClear: { [weak self] in
                self?.appState.clearBlocks()
            },
            settings: settings
        )

        print("[VoiceType] Pipeline ready (streaming: \(settings.streamingMode)).")
    }

    // MARK: - Public

    func toggleRecording() {
        if appState.recordingState == .recording {
            hotkeyManager.resetState()
            Task { await stopRecordingAndTranscribe() }
        } else {
            if !appState.panelVisible {
                appState.panelVisible = true
            }
            hotkeyManager.resetState()
            startRecording()
        }
    }

    func copyAllText() {
        let text = appState.allText
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Recording (dispatch to batch or streaming)

    private func startRecording() {
        guard appState.isEnabled else {
            print("[VoiceType] Disabled — ignoring hotkey")
            hotkeyManager.resetState()
            return
        }

        if !appState.panelVisible {
            appState.panelVisible = true
        }

        if appState.recordingState != .idle && appState.recordingState != .done {
            print("[VoiceType] Resetting stuck state: \(appState.recordingState)")
            cancelTimers()
            appState.recordingState = .idle
            appState.resetStreamingText()
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        guard micStatus == .authorized else {
            print("[VoiceType] Microphone not authorized. Requesting...")
            Task {
                let granted = await AudioCapture.requestPermission()
                print("[VoiceType] Microphone: \(granted ? "granted" : "denied")")
            }
            hotkeyManager.resetState()
            return
        }

        if settings.streamingMode {
            startStreamingRecording()
        } else {
            startBatchRecording()
        }
    }

    // MARK: - Batch Recording (original flow)

    private func startBatchRecording() {
        do {
            try audioCapture.startRecording()
            appState.recordingState = .recording
            appState.recordingDuration = 0
            appState.audioLevel = 0
            appState.audioLevelHistory = []
            startLevelTimer()

            if settings.soundEnabled {
                NSSound(named: "Tink")?.play()
            }

            print("[VoiceType] Batch recording...")
        } catch {
            print("[VoiceType] Failed to start recording: \(error)")
            appState.recordingState = .idle
            hotkeyManager.resetState()
        }
    }

    // MARK: - Streaming Recording (real-time)

    private func startStreamingRecording() {
        appState.isStreaming = true
        appState.recordingState = .recording
        appState.recordingDuration = 0
        appState.audioLevel = 0
        appState.audioLevelHistory = []
        appState.streamingConfirmedText = ""
        appState.streamingHypothesisText = ""

        // Duration timer only (audio levels come from streaming callback)
        startDurationTimer()

        if settings.soundEnabled {
            NSSound(named: "Tink")?.play()
        }

        print("[VoiceType] Streaming recording...")

        Task {
            do {
                try await transcriptionEngine.startStreaming(
                    language: settings.language
                ) { [weak self] oldState, newState in
                    // Callback fires on AudioStreamTranscriber actor — dispatch to main
                    Task { @MainActor [weak self] in
                        guard let self else { return }

                        // Update confirmed text
                        let confirmed = newState.confirmedSegments
                            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .joined(separator: " ")
                        self.appState.streamingConfirmedText = confirmed

                        // Update hypothesis text
                        let hypothesis = newState.unconfirmedSegments
                            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .joined(separator: " ")
                        self.appState.streamingHypothesisText = hypothesis

                        // Update audio levels from buffer energy
                        if !newState.bufferEnergy.isEmpty {
                            let recentEnergy = Array(newState.bufferEnergy.suffix(50))
                            self.appState.audioLevelHistory = recentEnergy
                            self.appState.audioLevel = recentEnergy.last ?? 0
                        }
                    }
                }
            } catch {
                print("[VoiceType] Streaming failed: \(error)")
                self.cancelTimers()
                self.appState.recordingState = .idle
                self.appState.resetStreamingText()
                self.hotkeyManager.resetState()
            }
        }
    }

    // MARK: - Stop Recording

    private func stopRecordingAndTranscribe() async {
        guard appState.recordingState == .recording else {
            print("[VoiceType] Not recording — nothing to stop")
            hotkeyManager.resetState()
            appState.recordingState = .idle
            return
        }

        if appState.isStreaming {
            await stopStreamingAndFinalize()
        } else {
            await stopBatchAndTranscribe()
        }
    }

    // MARK: - Batch Stop + Transcribe

    private func stopBatchAndTranscribe() async {
        let duration = appState.recordingDuration  // capture BEFORE cancelTimers zeroes it
        cancelTimers()
        let samples = audioCapture.stopRecording()
        print("[VoiceType] Captured \(samples.count) samples (\(String(format: "%.1f", duration))s)")

        guard samples.count > 8000 else {
            print("[VoiceType] Too short — need at least 0.5s")
            appState.recordingState = .idle
            return
        }

        appState.recordingState = .transcribing
        appState.transcribingElapsed = 0
        startTranscribeTimer()
        print("[VoiceType] Transcribing...")

        do {
            let text = try await transcriptionEngine.transcribe(audioSamples: samples)
            cancelTimers()
            print("[VoiceType] Result: \"\(text)\"")

            guard !text.isEmpty else {
                print("[VoiceType] Empty — skipping")
                appState.recordingState = .idle
                return
            }

            finalizeTranscription(text, duration: duration)

        } catch {
            cancelTimers()
            print("[VoiceType] Transcription failed: \(error)")
            appState.recordingState = .idle
        }
    }

    // MARK: - Streaming Stop + Finalize

    private func stopStreamingAndFinalize() async {
        let duration = appState.recordingDuration  // capture BEFORE cancelTimers zeroes it
        cancelTimers()
        await transcriptionEngine.stopStreaming()

        // Combine confirmed + final hypothesis as the complete text
        let finalText = [appState.streamingConfirmedText, appState.streamingHypothesisText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        appState.resetStreamingText()

        guard !finalText.isEmpty else {
            print("[VoiceType] Streaming produced no text")
            appState.recordingState = .idle
            return
        }

        print("[VoiceType] Streaming result: \"\(finalText)\"")
        finalizeTranscription(finalText, duration: duration)
    }

    // MARK: - Shared Finalization

    private func finalizeTranscription(_ text: String, duration: TimeInterval) {
        let previousWordCount = (try? historyStore.totalWordCount()) ?? 0

        // Session stats
        appState.lastSessionWordCount = text.split(separator: " ").count
        appState.lastSessionDuration = duration

        appState.appendBlock(text)
        appState.recordingState = .done

        try? historyStore.insert(text: text, appName: "VoiceType", appBundleID: Bundle.main.bundleIdentifier ?? "com.voicetype")

        if settings.soundEnabled {
            NSSound(named: "Pop")?.play()
        }

        // Settle back to idle after brief done indicator
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if appState.recordingState == .done {
                appState.recordingState = .idle
            }
        }

        // Check milestones
        let newWordCount = (try? historyStore.totalWordCount()) ?? 0
        let newDictationCount = (try? historyStore.totalDictationCount()) ?? 0

        if let milestone = StatsTracker.milestone(forDictationCount: newDictationCount) {
            StatsTracker.showMilestoneNotification(milestone)
        }
        if let milestone = StatsTracker.checkTimeMilestone(previousWordCount: previousWordCount, newWordCount: newWordCount) {
            StatsTracker.showMilestoneNotification(milestone)
        }

        try? historyStore.pruneKeeping(count: 50)
    }

    // MARK: - Timers

    private func startLevelTimer() {
        levelTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { break }
                self.appState.recordingDuration += 0.1
                let level = self.audioCapture.currentLevel
                self.appState.audioLevel = level

                self.appState.audioLevelHistory.append(level)
                if self.appState.audioLevelHistory.count > 50 {
                    self.appState.audioLevelHistory.removeFirst()
                }
            }
        }
    }

    private func startDurationTimer() {
        levelTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { break }
                self.appState.recordingDuration += 0.1
            }
        }
    }

    private func startTranscribeTimer() {
        transcribeTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { break }
                self.appState.transcribingElapsed += 0.1
            }
        }
    }

    private func cancelTimers() {
        levelTimer?.cancel()
        levelTimer = nil
        transcribeTimer?.cancel()
        transcribeTimer = nil
        appState.recordingDuration = 0
        appState.audioLevel = 0
        appState.transcribingElapsed = 0
    }
}
