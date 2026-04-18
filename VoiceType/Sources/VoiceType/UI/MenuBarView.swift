import SwiftUI

struct MenuBarView: View {
    @ObservedObject var pipeline: DictationPipeline

    @State private var recentRecords: [TranscriptionRecord] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            openNotepadButton
            Divider()
            HistoryView(records: recentRecords) { record in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.text, forType: .string)
            }
            Divider()
            hotkeyHints
            Divider()
            footer
        }
        .frame(width: 320)
        .onAppear { refreshData() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text("VoiceType")
                .font(VTFont.title())
                .tracking(0.8)

            Spacer()
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm + 2)
    }

    private var statusColor: Color {
        switch pipeline.appState.recordingState {
        case .idle: VTColors.textMuted.opacity(0.5)
        case .recording: VTColors.recording
        case .transcribing: VTColors.accent
        case .done: VTColors.success
        }
    }

    // MARK: - Open Notepad

    private var openNotepadButton: some View {
        Button(action: {
            pipeline.notepadController.show()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .font(.system(size: 14))
                    .foregroundStyle(VTColors.accent)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Open Notepad")
                        .font(.system(size: 13, weight: .medium))
                    Text("Dictate and collect text blocks")
                        .font(VTFont.caption())
                        .foregroundStyle(VTColors.textMuted)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 10))
                    .foregroundStyle(VTColors.textMuted)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm + 4)
    }

    // MARK: - Hotkey Hints

    private var hotkeyHints: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                KeyCap(label: "\u{21E7}")
                KeyCap(label: "\u{2318}")
                KeyCap(label: "Space")
            }
            Spacer()
            Text("Toggle recording")
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted)
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm + 2)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Quit VoiceType") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .buttonStyle(.plain)
            .font(VTFont.body())

            Spacer()

            Text("v0.1.0")
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted.opacity(0.5))
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm + 2)
    }

    // MARK: - Data

    private func refreshData() {
        recentRecords = (try? pipeline.historyStore.fetchRecent(limit: 5)) ?? []
    }

}
