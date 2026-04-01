import Foundation

final class ModelManager: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var isModelReady = false
    @Published var currentModelName: String = "large-v3_turbo"

    private let modelDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("VoiceType/Models", isDirectory: true)
    }()

    /// Ensures the model directory exists.
    func ensureModelDirectory() throws {
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
    }

    /// Returns the local path for a model if it exists.
    func localModelPath(for model: String) -> String? {
        let path = modelDirectory.appendingPathComponent(model)
        return FileManager.default.fileExists(atPath: path.path) ? path.path : nil
    }

    /// The storage directory path for WhisperKit to download models into.
    var storagePath: String {
        modelDirectory.path
    }
}
