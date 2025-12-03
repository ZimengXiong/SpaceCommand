import Carbon
import Combine
import Foundation
import ServiceManagement
import SwiftUI
import UserNotifications

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private let logger = Logger.shared
    private let notificationCenter = NotificationCenter.default

    private enum Keys {
        static let hotkeyEnabled = "hotkeyEnabled"
        static let showInDock = "showInDock"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let launchAtLogin = "launchAtLogin"
        static let customHotkey = "customHotkey"
        static let spaceMode = "spaceMode"
        static let spaceLabels = "spaceLabels"
    }

    @Published var hotkeyEnabled: Bool = true {
        didSet {
            defaults.set(hotkeyEnabled, forKey: Keys.hotkeyEnabled)
            logger.debug("Hotkey enabled changed to: \(hotkeyEnabled)")
        }
    }

    @Published var spaceLabels: [String: String] = [:] {
        didSet {
            defaults.set(spaceLabels, forKey: Keys.spaceLabels)
        }
    }

    @Published var showInDock: Bool = false {
        didSet {
            defaults.set(showInDock, forKey: Keys.showInDock)
            updateDockVisibility()
        }
    }

    @Published var showMenuBarIcon: Bool = true {
        didSet {
            defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon)
            updateMenuBarIconVisibility()
        }
    }

    @Published var launchAtLogin: Bool = false {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var customHotkey: KeyboardShortcut = KeyboardShortcut.cmdShiftSpace {
        didSet {
            saveCustomHotkey()
            notifyHotkeyChange()
        }
    }

    @Published var spaceMode: SpaceMode = .auto {
        didSet {
            defaults.set(spaceMode.rawValue, forKey: Keys.spaceMode)
            logger.info("Space mode changed to: \(spaceMode.displayName)")
        }
    }

    init() {
        setupDefaultValues()
        loadSettings()
        initializeNotifications()
        logger.info("AppSettings initialized successfully")
    }

    private func setupDefaultValues() {
        do {
            let encoded = try JSONEncoder().encode(KeyboardShortcut.cmdShiftSpace)
            defaults.register(
                defaults: [
                    Keys.hotkeyEnabled: true,
                    Keys.showInDock: false,
                    Keys.showMenuBarIcon: true,
                    Keys.launchAtLogin: false,
                    Keys.spaceMode: "auto",
                    Keys.customHotkey: encoded,
                ])
        } catch {
            defaults.register(
                defaults: [
                    Keys.hotkeyEnabled: true,
                    Keys.showInDock: false,
                    Keys.showMenuBarIcon: true,
                    Keys.launchAtLogin: false,
                    Keys.spaceMode: "auto",
                ])
        }
    }

    private func loadSettings() {
        hotkeyEnabled = defaults.bool(forKey: Keys.hotkeyEnabled)
        showInDock = defaults.bool(forKey: Keys.showInDock)

        showMenuBarIcon = defaults.bool(forKey: Keys.showMenuBarIcon)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        loadCustomHotkey()
        loadSpaceMode()
        loadSpaceLabels()
    }

    private func loadCustomHotkey() {
        if let data = defaults.data(forKey: Keys.customHotkey),
            let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
        {
            customHotkey = decoded
        } else {
            customHotkey = KeyboardShortcut.cmdShiftSpace
            logger.warning("Failed to load custom hotkey, using default")
        }
    }

    private func loadSpaceMode() {
        if let modeString = defaults.string(forKey: Keys.spaceMode),
            let mode = SpaceMode(rawValue: modeString)
        {
            spaceMode = mode
        } else {
            spaceMode = .auto
            logger.warning("Failed to load space mode, using default (.auto)")
        }
    }

    private func loadSpaceLabels() {
        if let labels = defaults.dictionary(forKey: Keys.spaceLabels) as? [String: String] {
            spaceLabels = labels
        } else if let oldLabels = defaults.dictionary(forKey: "nativeSpaceNames")
            as? [String: String]
        {
            spaceLabels = oldLabels
            logger.info("Migrated labels from NativeAdapter storage")
        }
    }

    func getLabel(for spaceId: String) -> String? {
        return spaceLabels[spaceId]
    }

    func setLabel(for spaceId: String, label: String?) {
        if let label = label, !label.isEmpty {
            spaceLabels[spaceId] = label
        } else {
            spaceLabels.removeValue(forKey: spaceId)
        }
    }

    private func initializeNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            granted, error in
            if let error = error {
                self.logger.error(
                    "Failed to request notification permission: \(error.localizedDescription)")
            } else {
                self.logger.debug("Notification permission granted: \(granted)")
            }
        }
    }

    private func saveCustomHotkey() {
        do {
            let encoded = try JSONEncoder().encode(customHotkey)
            defaults.set(encoded, forKey: Keys.customHotkey)
        } catch {
            logger.error("Failed to save custom hotkey: \(error)")
        }
    }

    private func notifyHotkeyChange() {
        notificationCenter.post(name: .hotkeyDidChange, object: customHotkey)
    }

    private func updateDockVisibility() {
        if showInDock {
            NSApp.setActivationPolicy(.regular)
            logger.info("App will show in Dock")
        } else {
            NSApp.setActivationPolicy(.accessory)
            logger.info("App will hide from Dock")
        }
    }

    private func updateLaunchAtLogin() {
        let operation = launchAtLogin ? "enable" : "disable"
        logger.info("Attempting to \(operation) launch at login")

        let success = launchAtLogin ? enableLaunchAtLogin() : disableLaunchAtLogin()

        if success {
            showLoginNotification(success: true, enabled: launchAtLogin)
            logger.info("Successfully \(operation)d launch at login")
        } else {
            showLoginNotification(success: false, enabled: launchAtLogin)
            logger.error("Failed to \(operation) launch at login")
        }
    }

    private func updateMenuBarIconVisibility() {

        notificationCenter.post(name: .menuBarIconVisibilityDidChange, object: showMenuBarIcon)
        logger.info("Menu bar icon visibility changed: \(showMenuBarIcon)")
    }

    private func enableLaunchAtLogin() -> Bool {
        do {
            try SMAppService.mainApp.register()
            return true
        } catch {
            logger.error("Failed to enable launch at login: \(error)")
            return false
        }
    }

    private func disableLaunchAtLogin() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            return true
        } catch {
            logger.error("Failed to disable launch at login: \(error)")
            return false
        }
    }

    private func showLoginNotification(success: Bool, enabled: Bool) {
        let content = UNMutableNotificationContent()

        if success {
            content.title = "SpaceCommand"
            content.body =
                enabled
                ? "SpaceCommand added to system startup"
                : "SpaceCommand removed from system startup"
            content.sound = .default
        } else {
            content.title = "SpaceCommand"
            content.body =
                enabled
                ? "Failed to add to system startup. Please check System Settings > General > Login Items"
                : "Failed to remove from system startup"
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "loginItemChange",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }

    func resetToDefaults() {
        hotkeyEnabled = true
        showInDock = false
        showMenuBarIcon = true
        launchAtLogin = false
        customHotkey = KeyboardShortcut.cmdShiftSpace
        spaceMode = .auto
        logger.info("AppSettings reset to defaults")
    }
}
