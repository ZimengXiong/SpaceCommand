import SwiftUI
import Carbon

@main
struct SpaceCommandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(spaceManager: SpaceManager.shared)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingPanel: FloatingPanel?
    // Settings window is now handled by SwiftUI
    private var hotkeyManager: HotkeyManager?
    // spaceManager is now a singleton accessed via SpaceManager.shared
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize space manager (singleton)
        let spaceManager = SpaceManager.shared
        
        // Create and configure floating panel
        floatingPanel = FloatingPanel(spaceManager: spaceManager, onOpenSettings: { [weak self] in
            self?.openSettingsMenu()
        })
        
        // Setup global hotkey (Cmd+Shift+Space)
        hotkeyManager = HotkeyManager { [weak self] in
            self?.togglePanel()
        }
        hotkeyManager?.register()
        
        // Setup menu bar
        setupMenuBar()
        
        print("SpaceCommand v\(AppInfo.version) launched. Press Cmd+Shift+Space to activate.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregister()
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
        // Use standard macOS selector to open settings
        NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)
        
        // Also hide the panel if it's open
        floatingPanel?.hidePanel()
        NSApp.activate(ignoringOtherApps: true)
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
    
    // Manual settings window management removed in favor of SwiftUI Settings scene
}
