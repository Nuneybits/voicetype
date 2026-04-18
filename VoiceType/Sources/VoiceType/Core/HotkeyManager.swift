import Foundation
import HotKey
import Carbon

@MainActor
final class HotkeyManager: ObservableObject {
    private var hotKey: HotKey?
    private var isRecording = false

    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?

    func setup() {
        hotKey = HotKey(key: .space, modifiers: [.command, .shift])
        print("[VoiceType] Hotkey registered: Cmd+Shift+Space")

        hotKey?.keyDownHandler = { [weak self] in
            guard let self else { return }

            if self.isRecording {
                // Second press — stop recording and transcribe
                print("[VoiceType] Hotkey: STOP recording")
                self.isRecording = false
                self.onRecordingStop?()
            } else {
                // First press — start recording
                print("[VoiceType] Hotkey: START recording")
                self.isRecording = true
                self.onRecordingStart?()
            }
        }
        // No keyUp handler needed for toggle mode
    }

    func teardown() {
        hotKey = nil
        isRecording = false
    }

    /// Reset state if recording fails or is cancelled
    func resetState() {
        isRecording = false
    }
}
