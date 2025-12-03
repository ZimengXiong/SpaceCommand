import AppKit
import SwiftUI

/// A floating, non-activating panel for the OmniBox interface
class FloatingPanel: NSPanel {
    private let spaceManager: SpaceManager
    private let onOpenSettings: () -> Void
    private var hostingView: NSHostingView<OmniBoxView>?

    init(spaceManager: SpaceManager, onOpenSettings: @escaping () -> Void) {
        self.spaceManager = spaceManager
        self.onOpenSettings = onOpenSettings

        let panelWidth: CGFloat = 600
        let panelHeight: CGFloat = 400

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelX = (screenFrame.width - panelWidth) / 2 + screenFrame.origin.x
        let panelY = (screenFrame.height - panelHeight) / 2 + screenFrame.origin.y + 100

        let contentRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        setupContent()
    }

    private func configurePanel() {
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false  // We use SwiftUI shadow instead
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = true

        self.acceptsMouseMovedEvents = true
        self.becomesKeyOnlyIfNeeded = true

        self.delegate = self
    }

    private func setupContent() {
        let omniBoxView = OmniBoxView(
            spaceManager: spaceManager,
            onDismiss: { [weak self] in
                self?.hidePanel()
            },
            onOpenSettings: { [weak self] in
                self?.hidePanel()
                self?.onOpenSettings()
            }
        )

        let hostingView = NSHostingView(rootView: omniBoxView)
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]

        self.contentView = hostingView
        self.hostingView = hostingView
    }

    func showPanel() {

        if let screen = NSScreen.main {
            let panelWidth = self.frame.width
            let panelHeight = self.frame.height
            let screenFrame = screen.visibleFrame
            let panelX = (screenFrame.width - panelWidth) / 2 + screenFrame.origin.x
            let panelY = (screenFrame.height - panelHeight) / 2 + screenFrame.origin.y + 100
            self.setFrameOrigin(NSPoint(x: panelX, y: panelY))
        }

        setupContent()

        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
    }

    func hidePanel() {
        self.orderOut(nil)
    }

    // Allow the panel to become key window for keyboard input
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

extension FloatingPanel: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        hidePanel()
    }
}
