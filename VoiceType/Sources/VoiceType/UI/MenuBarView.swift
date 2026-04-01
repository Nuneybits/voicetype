import SwiftUI

struct MenuBarView: View {
    @ObservedObject var pipeline: DictationPipeline

    @State private var recentRecords: [TranscriptionRecord] = []
    @State private var timeSavedText: String = "0m"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            statsRow
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
        HStack {
            Text("VoiceType")
                .font(VTFont.title())
            Spacer()
            Toggle("", isOn: $pipeline.appState.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm)
    }

    // MARK: - Stats

    private var statsRow: some View {
        Text("You've saved \(timeSavedText) typing this month.")
            .font(VTFont.caption())
            .foregroundStyle(VTColors.textMuted)
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.sm)
    }

    // MARK: - Hotkey Hints

    private var hotkeyHints: some View {
        HStack {
            Text("\u{2325}Space")
                .font(VTFont.mono())
            Spacer()
            Text("Hold or toggle")
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted)
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Button("Quit VoiceType") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func refreshData() {
        recentRecords = (try? pipeline.historyStore.fetchRecent(limit: 5)) ?? []
        let totalWords = (try? pipeline.historyStore.totalWordCount()) ?? 0
        let minutes = StatsTracker.timeSaved(wordCount: totalWords)
        timeSavedText = StatsTracker.formatTimeSaved(minutes: minutes)
    }
}
