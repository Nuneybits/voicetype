import Foundation

final class UserSettings: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var autoPunctuation: Bool {
        didSet { UserDefaults.standard.set(autoPunctuation, forKey: "autoPunctuation") }
    }
    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "language") }
    }
    @Published var silenceTimeout: Double {
        didSet { UserDefaults.standard.set(silenceTimeout, forKey: "silenceTimeout") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var streamingMode: Bool {
        didSet { UserDefaults.standard.set(streamingMode, forKey: "streamingMode") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.autoPunctuation = defaults.object(forKey: "autoPunctuation") as? Bool ?? true
        self.language = defaults.string(forKey: "language") ?? "en"
        self.silenceTimeout = defaults.object(forKey: "silenceTimeout") as? Double ?? 2.0
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        self.streamingMode = defaults.object(forKey: "streamingMode") as? Bool ?? false
    }
}
