import SwiftUI
import Carbon

@main
struct SpaceCommandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We handle settings manually in AppDelegate to ensure it opens reliably from the agent app
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingPanel: FloatingPanel?
    private var hotkeyManager: HotkeyManager?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize space manager (singleton)
        let spaceManager = SpaceManager.shared
        
        // Create and configure floating panel
        floatingPanel = FloatingPanel(spaceManager: spaceManager, onOpenSettings: { [weak self] in
            self?.openSettingsMenu()
        })
        
        // Setup global hotkey (Cmd+Shift+Space)
        hotkeyManager = HotkeyManager()
        hotkeyManager?.registerDefaultHotkey { [weak self] in
            self?.togglePanel()
        }
        
        // Register Cmd+, as hotkey for settings
        hotkeyManager?.register(key: UInt32(kVK_ANSI_Comma), modifierFlags: [.command]) { [weak self] in
            self?.openSettingsMenu()
        }
        
        // Setup menu bar
        setupMenuBar()
        
        print("SpaceCommand v\(AppInfo.version) launched. Press Cmd+Shift+Space to activate.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregisterAll()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3.topleft.filled", accessibilityDescription: "SpaceCommand")
            button.image?.size = NSSize(width: 18, height: 18)
        }
        
        let menu = NSMenu()
        
        // App title
        let titleItem = NSMenuItem(title: "SpaceCommand v\(AppInfo.version)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Open switcher
        let openItem = NSMenuItem(title: "Open Switcher", action: #selector(openSwitcher), keyEquivalent: " ")
        openItem.keyEquivalentModifierMask = [.command, .shift]
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsMenu), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit SpaceCommand", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func openSwitcher() {
        togglePanel()
    }
    
    @objc private func openSettingsMenu() {
        // Hide the main panel first
        floatingPanel?.hidePanel()
        
        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Create or show settings window
        if settingsWindow == nil {
            let settingsView = SettingsView(spaceManager: SpaceManager.shared)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("Settings")
            window.title = "SpaceCommand Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            
            // Handle window close
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) { [weak self] _ in
                self?.settingsWindow = nil
            }
            
            self.settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func togglePanel() {
        guard let panel = floatingPanel else { return }
        
        if panel.isVisible {
            panel.hidePanel()
        } else {
            panel.showPanel()
        }
    }
}
