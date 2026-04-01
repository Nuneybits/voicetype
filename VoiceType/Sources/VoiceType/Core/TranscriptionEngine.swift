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

        let config = WhisperKitConfig(
            model: modelManager.currentModelName,
            downloadBase: URL(fileURLWithPath: modelManager.storagePath),
            verbose: false,
            prewarm: true
        )

        whisperKit = try await WhisperKit(config)
        isLoaded = true
    }

    /// Transcribe audio samples (16kHz mono Float32).
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
