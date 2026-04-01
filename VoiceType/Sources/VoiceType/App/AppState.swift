import SwiftUI

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case done
}

@MainActor
final class AppState: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isEnabled: Bool = true
    @Published var lastTranscription: String?
    @Published var activeAppName: String?

    /// Resets to idle after a brief delay (used after .done state)
    func resetAfterDone() {
        Task {
            try? await Task.sleep(for: .seconds(1))
            if recordingState == .done {
                recordingState = .idle
            }
        }
    }
}
