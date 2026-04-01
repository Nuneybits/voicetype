import Foundation
import HotKey
import Carbon

// MARK: - Press Type Detection

enum PressType: Equatable {
    case toggle
    case hold
}

final class PressTypeDetector {
    private var keyDownTime: Date?
    private let holdThreshold: TimeInterval

    init(holdThreshold: TimeInterval = 0.3) {
        self.holdThreshold = holdThreshold
    }

    func keyDown() {
        keyDownTime = Date()
    }

    func keyUp() -> PressType {
        guard let downTime = keyDownTime else { return .toggle }
        let duration = Date().timeIntervalSince(downTime)
        keyDownTime = nil
        return duration < holdThreshold ? .toggle : .hold
    }
}

// MARK: - Hotkey Manager

@MainActor
final class HotkeyManager: ObservableObject {
    private let detector = PressTypeDetector()
    private var hotKey: HotKey?
    private var isToggleRecording = false

    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?

    func setup() {
        hotKey = HotKey(key: .space, modifiers: [.option])

        hotKey?.keyDownHandler = { [weak self] in
            guard let self else { return }
            self.detector.keyDown()
            // Start recording immediately for hold-to-talk responsiveness
            self.onRecordingStart?()
        }

        hotKey?.keyUpHandler = { [weak self] in
            guard let self else { return }
            let pressType = self.detector.keyUp()

            switch pressType {
            case .hold:
                // Hold released — stop recording
                self.isToggleRecording = false
                self.onRecordingStop?()
            case .toggle:
                if self.isToggleRecording {
                    // Second tap — stop recording
                    self.isToggleRecording = false
                    self.onRecordingStop?()
                } else {
                    // First tap — recording already started on keyDown, mark toggle mode
                    self.isToggleRecording = true
                }
            }
        }
    }

    func teardown() {
        hotKey = nil
        isToggleRecording = false
    }
}
