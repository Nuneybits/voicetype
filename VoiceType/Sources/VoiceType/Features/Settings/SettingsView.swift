import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: UserSettings
    @ObservedObject var modelManager: ModelManager

    var body: some View {
        Form {
            Section("General") {
                HStack {
                    Text("Dictation hotkey")
                    Spacer()
                    Text("\u{2318}\u{21E7}Space")
                        .font(VTFont.mono())
                        .foregroundStyle(VTColors.textMuted)
                }
                Toggle("Sound effects", isOn: $settings.soundEnabled)
            }

            Section("Transcription") {
                Picker("Language", selection: $settings.language) {
                    Text("English").tag("en")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Japanese").tag("ja")
                    Text("Chinese").tag("zh")
                }

                Picker("Model", selection: $modelManager.currentModelName) {
                    Text("Large v3 Turbo (recommended)").tag("large-v3_turbo")
                    Text("Large v3 Turbo (compressed)").tag("openai_whisper-large-v3-v20240930_turbo_632MB")
                    Text("Base (fast, less accurate)").tag("base")
                }

                Toggle("Live transcription preview", isOn: $settings.streamingMode)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(VTColors.textMuted)
                }

                HStack {
                    Text("License")
                    Spacer()
                    Text("Free")
                        .foregroundStyle(VTColors.textMuted)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
    }
}
