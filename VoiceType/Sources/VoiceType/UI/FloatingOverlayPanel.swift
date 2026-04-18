import AppKit
import SwiftUI
import Combine

/// NSPanel subclass that accepts key status so SwiftUI buttons work.
class ClickablePanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        level = .floating
    }
}

/// A floating notepad panel for dictation.
/// Uses .nonactivatingPanel — accepts clicks without stealing focus from the active app.
@MainActor
final class NotepadPanelController {
    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()
    private weak var appState: AppState?

    func setup(
        appState: AppState,
        modelManager: ModelManager,
        onToggleRecording: @escaping () -> Void,
        onCopyAll: @escaping () -> Void,
        onClear: @escaping () -> Void,
        settings: UserSettings
    ) {
        self.appState = appState

        let panel = ClickablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        // Position: bottom-right, 80pt from edges
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 380 - 80
            let y = screenFrame.minY + 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let notepadView = NotepadView(
            appState: appState,
            modelManager: modelManager,
            onToggleRecording: onToggleRecording,
            onCopyAll: onCopyAll,
            onClear: onClear,
            onClose: { [weak self] in
                self?.hide()
            },
            settings: settings
        )
        let hostingView = NSHostingView(rootView: notepadView)
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        self.panel = panel

        // Observe panelVisible to show/hide
        appState.$panelVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                guard let self, let panel = self.panel else { return }
                if visible {
                    panel.orderFront(nil)
                } else {
                    panel.orderOut(nil)
                }
            }
            .store(in: &cancellables)
    }

    func show() {
        appState?.panelVisible = true
    }

    func hide() {
        appState?.panelVisible = false
    }

    func toggle() {
        if let appState {
            appState.panelVisible.toggle()
        }
    }

}
