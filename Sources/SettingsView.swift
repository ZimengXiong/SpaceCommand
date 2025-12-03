import Carbon
import ServiceManagement
import SwiftUI
import UserNotifications

/// App version and build information
struct AppInfo {
    static let version = "1.0.0"
    static let build = "1"
    static let name = "SpaceCommand"
    static let bundleId = "com.ZimengXiong.SpaceCommand"

    static var fullVersion: String {
        "\(version) (\(build))"
    }

    static var copyright: String {
        "© 2025 SpaceCommand"
    }

    static var systemInfo: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "macOS \(osVersion)"
    }
}

extension Notification.Name {
    static let hotkeyDidChange = Notification.Name("hotkeyDidChange")
}

/// Represents a keyboard shortcut
struct KeyboardShortcut: Codable, Equatable {
    var key: UInt32
    var modifiers: [String]  // "cmd", "shift", "option", "control"

    var displayString: String {
        var result = ""
        if modifiers.contains("cmd") { result += "⌘" }
        if modifiers.contains("shift") { result += "⇧" }
        if modifiers.contains("option") { result += "⌥" }
        if modifiers.contains("control") { result += "⌃" }

        let keyChar = keyToString()
        result += keyChar
        return result
    }

    private func keyToString() -> String {
        switch key {

        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_ForwardDelete): return "⌦"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        case UInt32(kVK_Home): return "Home"
        case UInt32(kVK_End): return "End"
        case UInt32(kVK_PageUp): return "PgUp"
        case UInt32(kVK_PageDown): return "PgDn"

        case UInt32(kVK_F1): return "F1"
        case UInt32(kVK_F2): return "F2"
        case UInt32(kVK_F3): return "F3"
        case UInt32(kVK_F4): return "F4"
        case UInt32(kVK_F5): return "F5"
        case UInt32(kVK_F6): return "F6"
        case UInt32(kVK_F7): return "F7"
        case UInt32(kVK_F8): return "F8"
        case UInt32(kVK_F9): return "F9"
        case UInt32(kVK_F10): return "F10"
        case UInt32(kVK_F11): return "F11"
        case UInt32(kVK_F12): return "F12"
        case UInt32(kVK_F13): return "F13"
        case UInt32(kVK_F14): return "F14"
        case UInt32(kVK_F15): return "F15"
        case UInt32(kVK_F16): return "F16"
        case UInt32(kVK_F17): return "F17"
        case UInt32(kVK_F18): return "F18"
        case UInt32(kVK_F19): return "F19"
        case UInt32(kVK_F20): return "F20"

        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"

        case UInt32(kVK_ANSI_0): return "0"
        case UInt32(kVK_ANSI_1): return "1"
        case UInt32(kVK_ANSI_2): return "2"
        case UInt32(kVK_ANSI_3): return "3"
        case UInt32(kVK_ANSI_4): return "4"
        case UInt32(kVK_ANSI_5): return "5"
        case UInt32(kVK_ANSI_6): return "6"
        case UInt32(kVK_ANSI_7): return "7"
        case UInt32(kVK_ANSI_8): return "8"
        case UInt32(kVK_ANSI_9): return "9"

        case UInt32(kVK_ANSI_Comma): return ","
        case UInt32(kVK_ANSI_Period): return "."
        case UInt32(kVK_ANSI_Slash): return "/"
        case UInt32(kVK_ANSI_Semicolon): return ";"
        case UInt32(kVK_ANSI_Quote): return "'"
        case UInt32(kVK_ANSI_LeftBracket): return "["
        case UInt32(kVK_ANSI_RightBracket): return "]"
        case UInt32(kVK_ANSI_Backslash): return "\\"
        case UInt32(kVK_ANSI_Equal): return "="
        case UInt32(kVK_ANSI_Minus): return "-"
        case UInt32(kVK_ANSI_Grave): return "`"
        default: return "Key\(key)"
        }
    }
}

/// Simple enum for space mode to avoid circular dependencies
enum SpaceMode: String, Codable, CaseIterable {
    case auto = "auto"
    case yabai = "yabai"
    case native = "native"

    var displayName: String {
        switch self {
        case .auto: return "Auto (Yabai if available)"
        case .yabai: return "Yabai"
        case .native: return "Native macOS"
        }
    }
}

/// User preferences stored in UserDefaults
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let hotkeyEnabled = "hotkeyEnabled"
        static let showInDock = "showInDock"
        static let launchAtLogin = "launchAtLogin"
        static let customHotkey = "customHotkey"
        static let spaceMode = "spaceMode"
    }

    // MARK: - General Settings
    @Published var hotkeyEnabled: Bool {
        didSet { defaults.set(hotkeyEnabled, forKey: Keys.hotkeyEnabled) }
    }

    @Published var showInDock: Bool {
        didSet {
            defaults.set(showInDock, forKey: Keys.showInDock)
            updateDockVisibility()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var customHotkey: KeyboardShortcut {
        didSet {
            if let encoded = try? JSONEncoder().encode(customHotkey) {
                defaults.set(encoded, forKey: Keys.customHotkey)
            }
            // Notify that hotkey changed so it can be re-registered
            NotificationCenter.default.post(name: .hotkeyDidChange, object: customHotkey)
        }
    }

    @Published var spaceMode: SpaceMode = .auto {
        didSet {
            defaults.set(spaceMode.rawValue, forKey: Keys.spaceMode)
        }
    }

    // MARK: - Initialization
    init() {
        let defaultHotkey = KeyboardShortcut(key: UInt32(kVK_Space), modifiers: ["cmd", "shift"])

        defaults.register(defaults: [
            Keys.hotkeyEnabled: true,
            Keys.showInDock: false,
            Keys.launchAtLogin: false,
            Keys.spaceMode: "auto",
        ])

        self.hotkeyEnabled = defaults.bool(forKey: Keys.hotkeyEnabled)
        self.showInDock = defaults.bool(forKey: Keys.showInDock)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

        if let data = defaults.data(forKey: Keys.customHotkey),
            let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
        {
            self.customHotkey = decoded
        } else {
            self.customHotkey = defaultHotkey
        }

        // Load space mode
        if let modeString = defaults.string(forKey: Keys.spaceMode),
            let mode = SpaceMode(rawValue: modeString)
        {
            self.spaceMode = mode
        } else {
            self.spaceMode = .auto
        }

        // Initialize notifications
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            granted, error in
            if let error = error {
                print("Failed to request notification permission: \(error)")
            }
        }
    }

    // MARK: - Actions
    private func updateDockVisibility() {
        if showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func updateLaunchAtLogin() {
        let success = launchAtLogin ? enableLaunchAtLogin() : disableLaunchAtLogin()

        if success {
            showLoginNotification(success: true, enabled: launchAtLogin)
        } else {
            showLoginNotification(success: false, enabled: launchAtLogin)
            // DO NOT revert the setting here to avoid infinite recursion loops in didSet
            print("Failed to update launch at login preference.")
        }
    }

    private func enableLaunchAtLogin() -> Bool {
        do {
            try SMAppService.mainApp.register()
            print("Successfully enabled launch at login for \(AppInfo.bundleId) via SMAppService")
            return true
        } catch {
            print("Failed to enable launch at login via SMAppService: \(error)")
            return false
        }
    }

    private func disableLaunchAtLogin() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            print("Successfully disabled launch at login for \(AppInfo.bundleId) via SMAppService")
            return true
        } catch {
            print("Failed to disable launch at login via SMAppService: \(error)")
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

        UNUserNotificationCenter.current().add(request) {
            error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }

    func resetToDefaults() {
        hotkeyEnabled = true
        showInDock = false
        launchAtLogin = false
        customHotkey = KeyboardShortcut(key: UInt32(kVK_Space), modifiers: ["cmd", "shift"])
        spaceMode = .auto
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 520)
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var isRecordingHotkey = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Keyboard Shortcut")
                    Spacer()
                    ShortcutRecorderButton(
                        shortcut: $settings.customHotkey,
                        isRecording: $isRecordingHotkey
                    )
                }

                Toggle("Enable Global Hotkey", isOn: $settings.hotkeyEnabled)
            } header: {
                Text("Activation")
            }

            Section {
                Picker("Mode", selection: $settings.spaceMode) {
                    ForEach(SpaceMode.allCases, id: \.self) {
                        mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Space Backend")
            }

            Section {
                Toggle("Show in Dock", isOn: $settings.showInDock)
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
    }
}

struct StatusBadge: View {
    let isActive: Bool
    let text: String
    let activeColor: Color
    let inactiveColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Shortcut Recorder Button
struct ShortcutRecorderButton: View {
    @Binding var shortcut: KeyboardShortcut
    @Binding var isRecording: Bool

    var body: some View {
        Button(action: { isRecording.toggle() }) {
            HStack(spacing: 4) {
                if isRecording {
                    Text("Type shortcut...")
                        .foregroundColor(.secondary)
                } else {
                    Text(shortcut.displayString)
                        .fontWeight(.medium)
                }
            }
            .font(.system(size: 12, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isRecording ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .background(
            ShortcutRecorderView(isRecording: $isRecording, shortcut: $shortcut)
        )
    }
}

// MARK: - NSView wrapper for keyboard event capture
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcut: KeyboardShortcut

    func makeNSView(context: Context) -> ShortcutCaptureView {
        let view = ShortcutCaptureView()
        view.onShortcutCaptured = { key, modifiers in
            shortcut = KeyboardShortcut(key: key, modifiers: modifiers)
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureView, context: Context) {
        if isRecording && !nsView.isRecording {
            nsView.startRecording()
        } else if !isRecording && nsView.isRecording {
            nsView.stopRecording()
        }
    }
}

class ShortcutCaptureView: NSView {
    var isRecording = false
    var onShortcutCaptured: ((UInt32, [String]) -> Void)?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var flagsMonitor: Any?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    func startRecording() {
        isRecording = true

        let handleKeyEvent: (NSEvent) -> Bool = { [weak self] event in
            guard let self = self, self.isRecording else { return false }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Escape cancels recording
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
                return true
            }

            // Require at least one modifier key to avoid binding plain letters/numbers
            let acceptableModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
            guard !modifiers.intersection(acceptableModifiers).isEmpty else {
                return false
            }

            var modifierStrings: [String] = []
            if modifiers.contains(.command) { modifierStrings.append("cmd") }
            if modifiers.contains(.shift) { modifierStrings.append("shift") }
            if modifiers.contains(.option) { modifierStrings.append("option") }
            if modifiers.contains(.control) { modifierStrings.append("control") }

            DispatchQueue.main.async {
                self.onShortcutCaptured?(UInt32(event.keyCode), modifierStrings)
                self.stopRecording()
            }
            return true
        }

        // Use local event monitor for when app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if handleKeyEvent(event) {
                return nil
            }
            return event
        }

        // Use global event monitor to capture system-reserved shortcuts
        // This requires Accessibility permissions but can capture more key combinations
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handleKeyEvent(event)
        }

        // Also monitor flagsChanged to detect modifier-only presses (for future use)
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            // Just pass through for now, but could be used to show modifier state
            return event
        }
    }

    func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }

    deinit {
        stopRecording()
    }
}

// MARK: - About Tab
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.accentColor.gradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                Image(systemName: "square.grid.3x3.topleft.filled")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)

            // App Info
            VStack(spacing: 8) {
                Text(AppInfo.name)
                    .font(.title2.weight(.bold))

                Text("Version \(AppInfo.fullVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Actions
            Link(destination: URL(string: "https://github.com/ZimengXiong/SpaceCommand")!) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                    Text("View on GitHub")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            // Footer Info
            VStack(spacing: 4) {
                Text(AppInfo.systemInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(AppInfo.bundleId)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary.opacity(0.6))

                Text(AppInfo.copyright)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.top, 8)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
