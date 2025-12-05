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
        static let launchAtLogin = "launchAtLogin"
        static let customHotkey = "customHotkey"
        static let spaceMode = "spaceMode"
        static let spaceLabels = "spaceLabels"
    }

    @Published var hotkeyEnabled: Bool = true {
        didSet {
            defaults.set(hotkeyEnabled, forKey: Keys.hotkeyEnabled)
        }
    }

    @Published var spaceLabels: [String: String] = [:] {
        didSet {
            defaults.set(spaceLabels, forKey: Keys.spaceLabels)
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
        }
    }

    init() {
        setupDefaultValues()
        loadSettings()
        initializeNotifications()
    }

    private func setupDefaultValues() {
        do {
            let encoded = try JSONEncoder().encode(KeyboardShortcut.cmdShiftSpace)
            defaults.register(
                defaults: [
                    Keys.hotkeyEnabled: true,
                    Keys.launchAtLogin: false,
                    Keys.spaceMode: "auto",
                    Keys.customHotkey: encoded,
                ])
        } catch {
            defaults.register(
                defaults: [
                    Keys.hotkeyEnabled: true,
                    Keys.launchAtLogin: false,
                    Keys.spaceMode: "auto",
                ])
        }
    }

    private func loadSettings() {
        hotkeyEnabled = defaults.bool(forKey: Keys.hotkeyEnabled)
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
        }
    }

    private func loadSpaceMode() {
        if let modeString = defaults.string(forKey: Keys.spaceMode),
            let mode = SpaceMode(rawValue: modeString)
        {
            spaceMode = mode
        } else {
            spaceMode = .auto
        }
    }

    private func loadSpaceLabels() {
        if let labels = defaults.dictionary(forKey: Keys.spaceLabels) as? [String: String] {
            spaceLabels = labels
        } else if let oldLabels = defaults.dictionary(forKey: "nativeSpaceNames")
            as? [String: String]
        {
            spaceLabels = oldLabels
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
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

    private func updateLaunchAtLogin() {
        let success = launchAtLogin ? enableLaunchAtLogin() : disableLaunchAtLogin()
        showLoginNotification(success: success, enabled: launchAtLogin)
    }

    private func enableLaunchAtLogin() -> Bool {
        do {
            try SMAppService.mainApp.register()
            return true
        } catch {
            return false
        }
    }

    private func disableLaunchAtLogin() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            return true
        } catch {
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
        launchAtLogin = false
        customHotkey = KeyboardShortcut.cmdShiftSpace
        spaceMode = .auto
    }
}
