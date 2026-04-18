import SwiftUI

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case done
}

struct TranscriptionBlock: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let timestamp: Date

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isEnabled: Bool = true
    @Published var lastTranscription: String?

    // Recording properties
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var transcribingElapsed: TimeInterval = 0
    @Published var audioLevelHistory: [Float] = []

    // Notepad properties
    @Published var transcriptionBlocks: [TranscriptionBlock] = []
    @Published var panelVisible: Bool = false

    // Session stats
    @Published var lastSessionWordCount: Int = 0
    @Published var lastSessionDuration: TimeInterval = 0
    var lastSessionWPM: Int {
        lastSessionDuration > 0 ? Int(Double(lastSessionWordCount) / (lastSessionDuration / 60)) : 0
    }

    // Streaming properties
    @Published var streamingConfirmedText: String = ""
    @Published var streamingHypothesisText: String = ""
    @Published var isStreaming: Bool = false

    func resetStreamingText() {
        streamingConfirmedText = ""
        streamingHypothesisText = ""
        isStreaming = false
    }

    var totalWords: Int {
        transcriptionBlocks.map(\.text).joined(separator: " ").split(separator: " ").count
    }

    var allText: String {
        transcriptionBlocks.map(\.text).joined(separator: "\n\n")
    }

    func appendBlock(_ text: String) {
        transcriptionBlocks.append(TranscriptionBlock(text: text, timestamp: Date()))
        lastTranscription = text
    }

    func clearBlocks() {
        transcriptionBlocks.removeAll()
        lastTranscription = nil
    }
}
