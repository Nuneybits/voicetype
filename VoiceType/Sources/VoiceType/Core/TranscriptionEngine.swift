import Foundation
import WhisperKit

@MainActor
final class TranscriptionEngine: ObservableObject {
    private var whisperKit: WhisperKit?
    private var unloadTask: Task<Void, Never>?

    @Published var isLoaded = false
    @Published var isTranscribing = false

    private let modelManager: ModelManager
    private let idleUnloadDelay: TimeInterval = 10

    // Streaming
    private var streamTranscriber: AudioStreamTranscriber?
    private var streamingTask: Task<Void, Error>?

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    /// Load the WhisperKit model. Downloads on first use.
    func loadModel() async throws {
        unloadTask?.cancel()

        if whisperKit != nil {
            isLoaded = true
            return
        }

        let needsDownload = modelManager.localModelPath(for: modelManager.currentModelName) == nil
        if needsDownload {
            modelManager.isDownloading = true
            print("[VoiceType] Downloading model '\(modelManager.currentModelName)'...")
        }

        let config = WhisperKitConfig(
            model: modelManager.currentModelName,
            downloadBase: URL(fileURLWithPath: modelManager.storagePath),
            verbose: false,
            prewarm: true
        )

        whisperKit = try await WhisperKit(config)
        isLoaded = true

        if needsDownload {
            modelManager.isDownloading = false
            modelManager.isModelReady = true
            print("[VoiceType] Model ready.")
        }
    }

    /// Transcribe audio samples (16kHz mono Float32) — batch mode.
    func transcribe(audioSamples: [Float]) async throws -> String {
        if !isLoaded {
            try await loadModel()
        }

        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        isTranscribing = true
        defer {
            isTranscribing = false
            scheduleUnload()
        }

        let results = try await whisperKit.transcribe(audioArray: audioSamples)
        let text = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")

        return text
    }

    // MARK: - Streaming

    /// Start real-time streaming transcription. The callback fires on the AudioStreamTranscriber actor
    /// context — callers must dispatch UI updates to @MainActor.
    func startStreaming(
        language: String = "en",
        onStateChange: @escaping @Sendable (AudioStreamTranscriber.State, AudioStreamTranscriber.State) -> Void
    ) async throws {
        if !isLoaded {
            try await loadModel()
        }

        guard let whisperKit, let tokenizer = whisperKit.tokenizer else {
            throw TranscriptionError.modelNotLoaded
        }

        // Cancel idle unload while streaming
        unloadTask?.cancel()
        isTranscribing = true

        let options = DecodingOptions(
            language: language == "auto" ? nil : language
        )

        let transcriber = AudioStreamTranscriber(
            audioEncoder: whisperKit.audioEncoder,
            featureExtractor: whisperKit.featureExtractor,
            segmentSeeker: whisperKit.segmentSeeker,
            textDecoder: whisperKit.textDecoder,
            tokenizer: tokenizer,
            audioProcessor: whisperKit.audioProcessor,
            decodingOptions: options,
            requiredSegmentsForConfirmation: 2,
            silenceThreshold: 0.3,
            useVAD: true,
            stateChangeCallback: onStateChange
        )

        streamTranscriber = transcriber

        // Must run in detached task — startStreamTranscription() blocks until stopped
        streamingTask = Task.detached {
            try await transcriber.startStreamTranscription()
        }

        print("[VoiceType] Streaming transcription started.")
    }

    /// Stop streaming transcription.
    func stopStreaming() async {
        if let transcriber = streamTranscriber {
            await transcriber.stopStreamTranscription()
        }
        streamingTask?.cancel()
        streamingTask = nil
        streamTranscriber = nil
        isTranscribing = false
        scheduleUnload()
        print("[VoiceType] Streaming transcription stopped.")
    }

    /// Schedule model unload after idle period to free memory.
    private func scheduleUnload() {
        unloadTask?.cancel()
        unloadTask = Task {
            try? await Task.sleep(for: .seconds(idleUnloadDelay))
            if !Task.isCancelled && !isTranscribing {
                whisperKit = nil
                isLoaded = false
            }
        }
    }
}

enum TranscriptionError: Error, LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "Whisper model is not loaded"
        }
    }
}
