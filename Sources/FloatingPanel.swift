import AppKit
import SwiftUI

/// A floating, non-activating panel for the OmniBox interface
class FloatingPanel: NSPanel {
    private let spaceManager: SpaceManager
    private var hostingView: NSHostingView<OmniBoxView>?
    
    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager
        
        // Panel dimensions
        let panelWidth: CGFloat = 600
        let panelHeight: CGFloat = 400
        
        // Center on screen
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelX = (screenFrame.width - panelWidth) / 2 + screenFrame.origin.x
        let panelY = (screenFrame.height - panelHeight) / 2 + screenFrame.origin.y + 100
        
        let contentRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
        
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        configurePanel()
        setupContent()
    }
    
    private func configurePanel() {
        // Panel behavior
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        
        // Allow keyboard input
        self.acceptsMouseMovedEvents = true
        self.becomesKeyOnlyIfNeeded = true
    }
    
    private func setupContent() {
        let omniBoxView = OmniBoxView(
            spaceManager: spaceManager,
            onDismiss: { [weak self] in
                self?.hidePanel()
            }
        )
        
        let hostingView = NSHostingView(rootView: omniBoxView)
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        self.contentView = hostingView
        self.hostingView = hostingView
    }
    
    func showPanel() {
        // Recenter on current screen
        if let screen = NSScreen.main {
            let panelWidth = self.frame.width
            let panelHeight = self.frame.height
            let screenFrame = screen.visibleFrame
            let panelX = (screenFrame.width - panelWidth) / 2 + screenFrame.origin.x
            let panelY = (screenFrame.height - panelHeight) / 2 + screenFrame.origin.y + 100
            self.setFrameOrigin(NSPoint(x: panelX, y: panelY))
        }
        
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        
        // Refresh content
        setupContent()
    }
    
    func hidePanel() {
        self.orderOut(nil)
    }
    
    // Allow the panel to become key window for keyboard input
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
