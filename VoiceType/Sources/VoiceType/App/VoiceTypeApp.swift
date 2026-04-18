import SwiftUI

@main
struct VoiceTypeApp: App {
    @StateObject private var settings = UserSettings()
    @StateObject private var pipeline: DictationPipeline

    init() {
        let s = UserSettings()
        _settings = StateObject(wrappedValue: s)
        _pipeline = StateObject(wrappedValue: DictationPipeline(settings: s))
    }

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
}
