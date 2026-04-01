import Foundation
import UserNotifications

enum Milestone: Equatable {
    case firstDictation
    case hundredDictations
    case thousandDictations
    case hourSaved

    var message: String {
        switch self {
        case .firstDictation: "Your first dictation! Welcome to VoiceType."
        case .hundredDictations: "You've dictated 100 times. You're a natural."
        case .thousandDictations: "1,000 dictations. You're basically a podcaster now."
        case .hourSaved: "VoiceType just saved you an hour. Not bad."
        }
    }
}

enum StatsTracker {
    private static let typingWPM: Double = 40
    private static let speakingWPM: Double = 150

    /// Calculate minutes saved by dictating instead of typing.
    static func timeSaved(wordCount: Int) -> Double {
        let typingMinutes = Double(wordCount) / typingWPM
        let speakingMinutes = Double(wordCount) / speakingWPM
        return typingMinutes - speakingMinutes
    }

    /// Format minutes into a human-readable string.
    static func formatTimeSaved(minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    /// Check if a dictation count triggers a milestone.
    static func milestone(forDictationCount count: Int) -> Milestone? {
        switch count {
        case 1: .firstDictation
        case 100: .hundredDictations
        case 1000: .thousandDictations
        default: nil
        }
    }

    /// Check if total time saved crossed the 1-hour threshold.
    static func checkTimeMilestone(previousWordCount: Int, newWordCount: Int) -> Milestone? {
        let previousMinutes = timeSaved(wordCount: previousWordCount)
        let newMinutes = timeSaved(wordCount: newWordCount)
        if previousMinutes < 60 && newMinutes >= 60 {
            return .hourSaved
        }
        return nil
    }

    /// Show a native macOS notification for a milestone.
    static func showMilestoneNotification(_ milestone: Milestone) {
        let content = UNMutableNotificationContent()
        content.title = "VoiceType"
        content.body = milestone.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "milestone-\(String(describing: milestone))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
