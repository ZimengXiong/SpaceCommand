import Carbon
import SwiftUI

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
    private var hotkeyObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {

        let spaceManager = SpaceManager.shared

        // Check and request permissions on first launch
        spaceManager.ensurePermissions()

        floatingPanel = FloatingPanel(
            spaceManager: spaceManager,
            onOpenSettings: { [weak self] in
                self?.openSettingsMenu()
            })

        // Setup global hotkey using saved settings
        hotkeyManager = HotkeyManager()
        let settings = AppSettings.shared

        hotkeyManager?.registerDefaultHotkey { [weak self] in
            self?.togglePanel()
        }

        hotkeyManager?.updateMainHotkey(
            key: settings.customHotkey.key, modifiers: settings.customHotkey.modifiers)

        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .hotkeyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let shortcut = notification.object as? KeyboardShortcut {
                self?.hotkeyManager?.updateMainHotkey(
                    key: shortcut.key, modifiers: shortcut.modifiers)
            }
        }

        hotkeyManager?.register(key: UInt32(kVK_ANSI_Comma), modifierFlags: [.command]) {
            [weak self] in
            self?.openSettingsMenu()
        }

        // Register Control+Option+Number keys for spaces 11-20
        setupSpaceNumberHotkeys()

        setupMenuBar()

        print("SpaceCommand v\(AppInfo.version) launched. Press Cmd+Shift+Space to activate.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregisterAll()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "square.grid.3x3.topleft.filled",
                accessibilityDescription: "SpaceCommand")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(
            title: "SpaceCommand v\(AppInfo.version)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(
            title: "Open Switcher", action: #selector(openSwitcher), keyEquivalent: " ")
        openItem.keyEquivalentModifierMask = [.command, .shift]
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...", action: #selector(openSettingsMenu), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit SpaceCommand", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func openSwitcher() {
        togglePanel()
    }

    @objc private func openSettingsMenu() {

        floatingPanel?.hidePanel()

        NSApp.activate(ignoringOtherApps: true)

        // Create or show settings window
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("Settings")
            window.title = "SpaceCommand Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.isReleasedWhenClosed = false

            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: window, queue: nil
            ) { [weak self] _ in
                self?.settingsWindow = nil
            }

            self.settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    /// Register Control+Option+Number hotkeys for spaces 11-20
    private func setupSpaceNumberHotkeys() {
        // Map number keys to space indices 11-20
        // 1 = Space 11, 2 = Space 12, ..., 9 = Space 19, 0 = Space 20
        let numberKeyMappings: [UInt32: Int] = [
            UInt32(kVK_ANSI_1): 11,
            UInt32(kVK_ANSI_2): 12,
            UInt32(kVK_ANSI_3): 13,
            UInt32(kVK_ANSI_4): 14,
            UInt32(kVK_ANSI_5): 15,
            UInt32(kVK_ANSI_6): 16,
            UInt32(kVK_ANSI_7): 17,
            UInt32(kVK_ANSI_8): 18,
            UInt32(kVK_ANSI_9): 19,
            UInt32(kVK_ANSI_0): 20,
        ]

        for (keyCode, spaceIndex) in numberKeyMappings {
            hotkeyManager?.register(key: keyCode, modifierFlags: [.control, .option]) {
                [weak self] in
                self?.handleSpaceNumberHotkey(spaceIndex: spaceIndex)
            }
        }

        print("Registered Control+Option+Number hotkeys for spaces 11-20")
    }

    /// Handle hotkey press for space switching
    @objc private func handleSpaceNumberHotkey(spaceIndex: Int) {
        print("Control+Option+\(spaceIndex - 10) pressed - switching to space \(spaceIndex)")

        let spaceManager = SpaceManager.shared

        // Check if we have any available backend
        if !spaceManager.hasAvailableBackend {
            print("SpaceManager: No backend available for space switching")
            return
        }

        // Switch to the space by index
        spaceManager.switchToSpace(by: spaceIndex)
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
