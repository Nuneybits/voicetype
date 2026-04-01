import Foundation

@MainActor
final class DictationPipeline: ObservableObject {
    let appState: AppState
    let hotkeyManager: HotkeyManager
    let audioCapture: AudioCapture
    let transcriptionEngine: TranscriptionEngine
    let textInjector: TextInjector
    let historyStore: HistoryStore
    let modelManager: ModelManager

    init() {
        self.appState = AppState()
        self.hotkeyManager = HotkeyManager()
        self.audioCapture = AudioCapture()
        self.modelManager = ModelManager()
        self.transcriptionEngine = TranscriptionEngine(modelManager: modelManager)
        self.textInjector = TextInjector()
        self.historyStore = HistoryStore()

        setupHotkeyCallbacks()
    }

    private func setupHotkeyCallbacks() {
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
    }

    func setup() {
        hotkeyManager.setup()
    }

    private func startRecording() {
        guard appState.isEnabled, appState.recordingState == .idle else { return }

        // Capture active app BEFORE recording starts
        appState.activeAppName = ActiveAppDetector.currentAppName()

        do {
            try audioCapture.startRecording()
            appState.recordingState = .recording
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecordingAndTranscribe() async {
        guard appState.recordingState == .recording else { return }

        let samples = audioCapture.stopRecording()
        appState.recordingState = .transcribing

        // Skip if too short (< 0.5 seconds of audio)
        guard samples.count > 8000 else {
            appState.recordingState = .idle
            return
        }

        do {
            let text = try await transcriptionEngine.transcribe(audioSamples: samples)

            guard !text.isEmpty else {
                appState.recordingState = .idle
                return
            }

            // Track stats before injection
            let previousWordCount = (try? historyStore.totalWordCount()) ?? 0
            _ = (try? historyStore.totalDictationCount()) ?? 0

            // Inject text into active app
            textInjector.injectText(text)

            // Save to history
            let appName = appState.activeAppName ?? "Unknown"
            let bundleID = ActiveAppDetector.currentAppBundleID()
            try? historyStore.insert(text: text, appName: appName, appBundleID: bundleID)

            // Update state
            appState.lastTranscription = text
            appState.recordingState = .done
            appState.resetAfterDone()

            // Check milestones
            let newWordCount = (try? historyStore.totalWordCount()) ?? 0
            let newDictationCount = (try? historyStore.totalDictationCount()) ?? 0

            if let milestone = StatsTracker.milestone(forDictationCount: newDictationCount) {
                StatsTracker.showMilestoneNotification(milestone)
            }
            if let milestone = StatsTracker.checkTimeMilestone(previousWordCount: previousWordCount, newWordCount: newWordCount) {
                StatsTracker.showMilestoneNotification(milestone)
            }

            // Prune history (free tier: 10 entries)
            try? historyStore.pruneKeeping(count: 10)

        } catch {
            print("Transcription failed: \(error)")
            appState.recordingState = .idle
        }
    }
}
