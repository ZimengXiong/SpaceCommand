import Carbon
import SwiftUI

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
        if modifiers.contains("control") { result += "⌃" }
        if modifiers.contains("option") { result += "⌥" }
        if modifiers.contains("shift") { result += "⇧" }
        if modifiers.contains("cmd") { result += "⌘" }

        let keyChar = keyToString()
        result += keyChar
        return result
    }

    /// Convert modifiers to CGEventFlags for keyboard simulation
    var cgEventFlags: CGEventFlags {
        var flags = CGEventFlags()
        if modifiers.contains("control") { flags.insert(.maskControl) }
        if modifiers.contains("option") { flags.insert(.maskAlternate) }
        if modifiers.contains("shift") { flags.insert(.maskShift) }
        if modifiers.contains("cmd") { flags.insert(.maskCommand) }
        return flags
    }

    /// Get the key code as CGKeyCode
    var keyCode: CGKeyCode {
        return CGKeyCode(key)
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

/// Container for all space switching shortcuts
struct SpaceSwitchShortcuts: Codable, Equatable {
    /// Shortcuts for spaces 1-20 (index 0 = space 1, etc.)
    var shortcuts: [KeyboardShortcut]

    /// Create default shortcuts:
    /// - Spaces 1-10: Control + Number (10 is Control+0)
    /// - Spaces 11-20: Control + Option + Number (11 is Control+Option+1, etc.)
    static func defaults() -> SpaceSwitchShortcuts {
        var shortcuts: [KeyboardShortcut] = []

        // Key codes for numbers 1-0 on keyboard
        let numberKeyCodes: [UInt32] = [
            UInt32(kVK_ANSI_1),  // 1
            UInt32(kVK_ANSI_2),  // 2
            UInt32(kVK_ANSI_3),  // 3
            UInt32(kVK_ANSI_4),  // 4
            UInt32(kVK_ANSI_5),  // 5
            UInt32(kVK_ANSI_6),  // 6
            UInt32(kVK_ANSI_7),  // 7
            UInt32(kVK_ANSI_8),  // 8
            UInt32(kVK_ANSI_9),  // 9
            UInt32(kVK_ANSI_0),  // 0 (for space 10)
        ]

        // Spaces 1-10: Control + Number
        for i in 0..<10 {
            shortcuts.append(
                KeyboardShortcut(
                    key: numberKeyCodes[i],
                    modifiers: ["control"]
                ))
        }

        // Spaces 11-20: Control + Option + Number
        for i in 0..<10 {
            shortcuts.append(
                KeyboardShortcut(
                    key: numberKeyCodes[i],
                    modifiers: ["control", "option"]
                ))
        }

        return SpaceSwitchShortcuts(shortcuts: shortcuts)
    }

    /// Get shortcut for a given space index (1-based)
    func shortcut(forSpace index: Int) -> KeyboardShortcut? {
        guard index >= 1 && index <= shortcuts.count else { return nil }
        return shortcuts[index - 1]
    }

    /// Update shortcut for a given space index (1-based)
    mutating func setShortcut(_ shortcut: KeyboardShortcut, forSpace index: Int) {
        guard index >= 1 && index <= shortcuts.count else { return }
        shortcuts[index - 1] = shortcut
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
        static let spaceSwitchShortcuts = "spaceSwitchShortcuts"
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
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
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

    @Published var spaceMode: SpaceMode {
        didSet {
            defaults.set(spaceMode.rawValue, forKey: Keys.spaceMode)
        }
    }

    @Published var spaceSwitchShortcuts: SpaceSwitchShortcuts {
        didSet {
            if let encoded = try? JSONEncoder().encode(spaceSwitchShortcuts) {
                defaults.set(encoded, forKey: Keys.spaceSwitchShortcuts)
            }
        }
    }

    // MARK: - Initialization
    init() {
        let defaultHotkey = KeyboardShortcut(key: UInt32(kVK_Space), modifiers: ["cmd", "shift"])
        let defaultSpaceSwitchShortcuts = SpaceSwitchShortcuts.defaults()

        defaults.register(defaults: [
            Keys.hotkeyEnabled: true,
            Keys.showInDock: false,
            Keys.launchAtLogin: false,
            Keys.spaceMode: SpaceMode.auto.rawValue,
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

        // Load space switch shortcuts
        if let data = defaults.data(forKey: Keys.spaceSwitchShortcuts),
            let decoded = try? JSONDecoder().decode(SpaceSwitchShortcuts.self, from: data)
        {
            self.spaceSwitchShortcuts = decoded
        } else {
            self.spaceSwitchShortcuts = defaultSpaceSwitchShortcuts
        }

        // Load space mode
        if let modeString = defaults.string(forKey: Keys.spaceMode),
            let mode = SpaceMode(rawValue: modeString)
        {
            self.spaceMode = mode
        } else {
            self.spaceMode = .auto
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

    func resetToDefaults() {
        hotkeyEnabled = true
        showInDock = false
        launchAtLogin = false
        customHotkey = KeyboardShortcut(key: UInt32(kVK_Space), modifiers: ["cmd", "shift"])
        spaceSwitchShortcuts = SpaceSwitchShortcuts.defaults()
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

            SpaceShortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var spaceManager = SpaceManager.shared
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
                Picker("Space Backend", selection: $settings.spaceMode) {
                    ForEach(SpaceMode.allCases, id: \.self) { mode in
                        HStack {
                            Text(mode.displayName)
                            if mode == .yabai && !spaceManager.isYabaiAvailable {
                                Text("(unavailable)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.menu)

                // Status indicators
                HStack {
                    Text("Active Backend:")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(spaceManager.hasAvailableBackend ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(spaceManager.activeAdapterName)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Yabai Status:")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(spaceManager.isYabaiAvailable ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(spaceManager.isYabaiAvailable ? "Available" : "Not Found")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Native Mode:")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(spaceManager.isNativeAvailable ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(spaceManager.isNativeAvailable ? "Available" : "Unavailable")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Space Backend")
            } footer: {
                Text(
                    "Auto mode uses Yabai if available, otherwise falls back to native macOS APIs. Native mode requires Accessibility permissions for space switching."
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Section {
                Toggle("Show in Dock", isOn: $settings.showInDock)
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Space Shortcuts Tab
struct SpaceShortcutsTab: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var recordingSpaceIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Space Switching Shortcuts")
                    .font(.headline)
                Spacer()
                Button("Reset to Defaults") {
                    settings.spaceSwitchShortcuts = SpaceSwitchShortcuts.defaults()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Text(
                "Configure keyboard shortcuts for switching to each space. Defaults: ⌃1-0 for spaces 1-10, ⌃⌥1-0 for spaces 11-20."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Scrollable list of shortcuts
            ScrollView {
                LazyVStack(spacing: 1) {
                    // Spaces 1-10
                    ForEach(1...10, id: \.self) { spaceIndex in
                        SpaceShortcutRow(
                            spaceIndex: spaceIndex,
                            shortcut: shortcutBinding(for: spaceIndex),
                            isRecording: recordingSpaceIndex == spaceIndex,
                            onStartRecording: {
                                recordingSpaceIndex = spaceIndex
                            },
                            onStopRecording: {
                                recordingSpaceIndex = nil
                            }
                        )
                    }

                    Divider()
                        .padding(.vertical, 8)

                    Text("Extended Spaces (11-20)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                    // Spaces 11-20
                    ForEach(11...20, id: \.self) { spaceIndex in
                        SpaceShortcutRow(
                            spaceIndex: spaceIndex,
                            shortcut: shortcutBinding(for: spaceIndex),
                            isRecording: recordingSpaceIndex == spaceIndex,
                            onStartRecording: {
                                recordingSpaceIndex = spaceIndex
                            },
                            onStopRecording: {
                                recordingSpaceIndex = nil
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
        }
    }

    private func shortcutBinding(for spaceIndex: Int) -> Binding<KeyboardShortcut> {
        Binding(
            get: {
                settings.spaceSwitchShortcuts.shortcut(forSpace: spaceIndex)
                    ?? KeyboardShortcut(key: 0, modifiers: [])
            },
            set: { newValue in
                var shortcuts = settings.spaceSwitchShortcuts
                shortcuts.setShortcut(newValue, forSpace: spaceIndex)
                settings.spaceSwitchShortcuts = shortcuts
            }
        )
    }
}

// MARK: - Space Shortcut Row
struct SpaceShortcutRow: View {
    let spaceIndex: Int
    @Binding var shortcut: KeyboardShortcut
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    var body: some View {
        HStack {
            Text("Space \(spaceIndex)")
                .font(.system(size: 13))
                .frame(width: 70, alignment: .leading)

            Spacer()

            SpaceShortcutRecorderButton(
                shortcut: $shortcut,
                isRecording: isRecording,
                onStartRecording: onStartRecording,
                onStopRecording: onStopRecording
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(6)
    }
}

// MARK: - Space Shortcut Recorder Button
struct SpaceShortcutRecorderButton: View {
    @Binding var shortcut: KeyboardShortcut
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    var body: some View {
        Button(action: {
            if isRecording {
                onStopRecording()
            } else {
                onStartRecording()
            }
        }) {
            HStack(spacing: 4) {
                if isRecording {
                    Text("Type shortcut...")
                        .foregroundColor(.secondary)
                } else {
                    Text(shortcut.displayString)
                        .fontWeight(.medium)
                }
            }
            .font(.system(size: 11, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        isRecording ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .background(
            SpaceShortcutRecorderView(
                isRecording: isRecording,
                shortcut: $shortcut,
                onStopRecording: onStopRecording
            )
        )
    }
}

// MARK: - Space Shortcut Recorder NSView
struct SpaceShortcutRecorderView: NSViewRepresentable {
    let isRecording: Bool
    @Binding var shortcut: KeyboardShortcut
    let onStopRecording: () -> Void

    func makeNSView(context: Context) -> SpaceShortcutCaptureView {
        let view = SpaceShortcutCaptureView()
        view.onShortcutCaptured = { key, modifiers in
            shortcut = KeyboardShortcut(key: key, modifiers: modifiers)
            onStopRecording()
        }
        view.onCancel = {
            onStopRecording()
        }
        return view
    }

    func updateNSView(_ nsView: SpaceShortcutCaptureView, context: Context) {
        if isRecording && !nsView.isRecording {
            nsView.startRecording()
        } else if !isRecording && nsView.isRecording {
            nsView.stopRecording()
        }
    }
}

class SpaceShortcutCaptureView: NSView {
    var isRecording = false
    var onShortcutCaptured: ((UInt32, [String]) -> Void)?
    var onCancel: (() -> Void)?
    private var localMonitor: Any?
    private var globalMonitor: Any?

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
                    self.onCancel?()
                    self.stopRecording()
                }
                return true
            }

            // Require at least one modifier key
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

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if handleKeyEvent(event) {
                return nil
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handleKeyEvent(event)
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
    }

    deinit {
        stopRecording()
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
        VStack(spacing: 16) {
            Spacer()

            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.gradient)
                    .frame(width: 64, height: 64)

                Image(systemName: "square.grid.3x3.topleft.filled")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }

            // App name and version
            VStack(spacing: 4) {
                Text(AppInfo.name)
                    .font(.system(size: 18, weight: .bold))
                Text("Version \(AppInfo.fullVersion)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // System info
            VStack(spacing: 2) {
                Text(AppInfo.systemInfo)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(AppInfo.bundleId)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            Text(AppInfo.copyright)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
