import SwiftUI

struct HistoryView: View {
    let records: [TranscriptionRecord]
    var onCopy: ((TranscriptionRecord) -> Void)?

    @State private var isExpanded: Bool = false

    var body: some View {
        if records.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Collapsible header
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Recent (\(records.count))")
                            .font(VTFont.caption())
                            .foregroundStyle(VTColors.textMuted)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(VTColors.textMuted)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, VTSpacing.md)
                .padding(.vertical, VTSpacing.sm)

                // Records — only when expanded
                if isExpanded {
                    ForEach(records.prefix(5)) { record in
                        HistoryRow(record: record) {
                            onCopy?(record)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("No dictations yet")
                .font(VTFont.body())
                .foregroundStyle(VTColors.textMuted)
            HStack(spacing: 3) {
                Text("Press")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted.opacity(0.7))
                KeyCap(label: "\u{21E7}")
                KeyCap(label: "\u{2318}")
                KeyCap(label: "Space")
                Text("to start")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
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
                        .font(.system(size: 10))
                        .foregroundStyle(VTColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? VTColors.surfaceHover : Color.clear)
                    .padding(.horizontal, VTSpacing.sm)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
