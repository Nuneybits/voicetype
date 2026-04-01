import AppKit

enum ActiveAppDetector {
    /// Returns the name of the currently active (frontmost) application.
    static func currentAppName() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }

    /// Returns the bundle identifier of the currently active application.
    static func currentAppBundleID() -> String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
    }

    /// Returns true if the active app is a code editor.
    static func isCodeEditor() -> Bool {
        let codeEditorBundleIDs = [
            "com.microsoft.VSCode",
            "com.todesktop.230313mzl4w4u92",  // Cursor
            "com.apple.dt.Xcode",
            "com.sublimetext.4",
            "co.gitbutler.app",
            "com.jetbrains.intellij",
        ]
        return codeEditorBundleIDs.contains(currentAppBundleID())
    }
}
