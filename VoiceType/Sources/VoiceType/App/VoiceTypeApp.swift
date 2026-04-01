import SwiftUI

@main
struct VoiceTypeApp: App {
    @StateObject private var pipeline = DictationPipeline()
    @StateObject private var settings = UserSettings()

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(pipeline: pipeline)
        } label: {
            RecordingIndicator(state: pipeline.appState.recordingState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings, modelManager: pipeline.modelManager)
        }
    }

    init() {
        // Pipeline setup after SwiftUI initializes
        DispatchQueue.main.async { [self] in
            if !showOnboarding {
                pipeline.setup()
            }
        }
    }
}
