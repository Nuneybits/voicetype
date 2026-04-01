import SwiftUI

struct RecordingIndicator: View {
    let state: RecordingState

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(iconColor)
            .font(.system(size: 14, weight: .medium))
            .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var iconName: String {
        switch state {
        case .idle: "mic.fill"
        case .recording: "mic.fill"
        case .transcribing: "ellipsis"
        case .done: "checkmark"
        }
    }

    private var iconColor: Color {
        switch state {
        case .idle: .primary
        case .recording: VTColors.recording
        case .transcribing: VTColors.accent
        case .done: VTColors.success
        }
    }
}
