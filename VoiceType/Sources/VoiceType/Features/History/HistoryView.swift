import SwiftUI

struct HistoryView: View {
    let records: [TranscriptionRecord]
    var onCopy: ((TranscriptionRecord) -> Void)?

    var body: some View {
        if records.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recent")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
                    .padding(.horizontal, VTSpacing.md)
                    .padding(.top, VTSpacing.sm)
                    .padding(.bottom, VTSpacing.xs)

                ForEach(records.prefix(5)) { record in
                    HistoryRow(record: record) {
                        onCopy?(record)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No dictations yet. Press \u{2325}Space to start.")
            .font(VTFont.caption())
            .foregroundStyle(VTColors.textMuted)
            .padding(VTSpacing.md)
    }
}

struct HistoryRow: View {
    let record: TranscriptionRecord
    let onCopy: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onCopy) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.preview)
                        .font(VTFont.body())
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Text(record.appName)
                        Text("\u{00B7}")
                        Text(record.relativeTime)
                    }
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
                }

                Spacer()

                if isHovering {
                    Image(systemName: "doc.on.doc")
                        .font(VTFont.caption())
                        .foregroundStyle(VTColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.xs)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
