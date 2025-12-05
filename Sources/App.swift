import Carbon
import SwiftUI

@main
struct SpaceCommandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingPanel: FloatingPanel?
    private var hotkeyManager: HotkeyManager?
    private var settingsWindow: NSWindow?
    private var hotkeyObserver: NSObjectProtocol?
    private let logger = Logger.shared

    func applicationDidFinishLaunching(_ notification: Notification) {

        NSApp.setActivationPolicy(.accessory)

        let spaceManager = SpaceManager.shared

        spaceManager.ensurePermissions()

        floatingPanel = FloatingPanel(
            spaceManager: spaceManager,
            onOpenSettings: { [weak self] in
                self?.openSettingsMenu()
            })

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

        setupSpaceNumberHotkeys()

        logger.info("SpaceCommand v\(AppInfo.version) launched. Press Cmd+Shift+Space to activate.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregisterAll()
    }

    private func openSettingsMenu() {

        floatingPanel?.hidePanel()

        NSApp.activate(ignoringOtherApps: true)

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

    private func setupSpaceNumberHotkeys() {
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
    }

    private func handleSpaceNumberHotkey(spaceIndex: Int) {
        let spaceManager = SpaceManager.shared
        guard spaceManager.hasAvailableBackend else { return }
        Task { await spaceManager.switchToSpace(by: spaceIndex) }
    }

    private func quitApp() {
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
