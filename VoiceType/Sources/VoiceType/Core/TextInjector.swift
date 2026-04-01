import AppKit
import CoreGraphics

final class TextInjector {
    private var savedClipboardItems: [NSPasteboardItem]?

    /// Save the current clipboard contents.
    func saveClipboard() {
        let pasteboard = NSPasteboard.general
        savedClipboardItems = pasteboard.pasteboardItems?.compactMap { item in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
    }

    /// Restore the previously saved clipboard contents.
    func restoreClipboard() {
        guard let items = savedClipboardItems else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
        savedClipboardItems = nil
    }

    /// Inject text into the active application via clipboard + Cmd+V.
    func injectText(_ text: String) {
        saveClipboard()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to let pasteboard settle
        usleep(50_000)

        simulatePaste()

        // Restore original clipboard after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.restoreClipboard()
        }
    }

    /// Simulate Cmd+V keystroke via CGEvent.
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key code 9 = "V"
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
