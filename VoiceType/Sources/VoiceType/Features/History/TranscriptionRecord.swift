import Foundation

struct TranscriptionRecord: Identifiable, Equatable {
    let id: Int64
    let text: String
    let appName: String
    let appBundleID: String
    let wordCount: Int
    let createdAt: Date

    var preview: String {
        let maxLength = 80
        if text.count <= maxLength { return text }
        return String(text.prefix(maxLength)) + "..."
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
