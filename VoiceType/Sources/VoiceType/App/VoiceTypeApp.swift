import SwiftUI

@main
struct VoiceTypeApp: App {
    var body: some Scene {
        MenuBarExtra("VoiceType", systemImage: "mic.fill") {
            Text("VoiceType is running")
                .padding()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.window)
    }
}
