import SwiftUI

/// App version and build information
struct AppInfo {
    static let version = "1.0.0"
    static let build = "1"
    static let name = "SpaceCommand"
    static let bundleId = "com.SpaceCommand.SpaceCommand"
    
    static var fullVersion: String {
        "\(version) (\(build))"
    }
    
    static var copyright: String {
        "© 2024 SpaceCommand"
    }
    
    static var systemInfo: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "macOS \(osVersion)"
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
        static let showModeIndicator = "showModeIndicator"
        static let accentColorName = "accentColorName"
        static let panelOpacity = "panelOpacity"
        static let showShortcutHints = "showShortcutHints"
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
    
    // MARK: - Appearance Settings
    @Published var showModeIndicator: Bool {
        didSet { defaults.set(showModeIndicator, forKey: Keys.showModeIndicator) }
    }
    
    @Published var accentColorName: String {
        didSet { defaults.set(accentColorName, forKey: Keys.accentColorName) }
    }
    
    @Published var panelOpacity: Double {
        didSet { defaults.set(panelOpacity, forKey: Keys.panelOpacity) }
    }
    
    @Published var showShortcutHints: Bool {
        didSet { defaults.set(showShortcutHints, forKey: Keys.showShortcutHints) }
    }
    
    // MARK: - Initialization
    init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.hotkeyEnabled: true,
            Keys.showInDock: false,
            Keys.launchAtLogin: false,
            Keys.showModeIndicator: true,
            Keys.accentColorName: "blue",
            Keys.panelOpacity: 0.95,
            Keys.showShortcutHints: true
        ])
        
        // Load saved values
        self.hotkeyEnabled = defaults.bool(forKey: Keys.hotkeyEnabled)
        self.showInDock = defaults.bool(forKey: Keys.showInDock)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showModeIndicator = defaults.bool(forKey: Keys.showModeIndicator)
        self.accentColorName = defaults.string(forKey: Keys.accentColorName) ?? "blue"
        self.panelOpacity = defaults.double(forKey: Keys.panelOpacity)
        self.showShortcutHints = defaults.bool(forKey: Keys.showShortcutHints)
    }
    
    // MARK: - Computed Properties
    var accentColor: Color {
        switch accentColorName {
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "teal": return .teal
        default: return .accentColor
        }
    }
    
    static let availableColors = [
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("pink", Color.pink),
        ("red", Color.red),
        ("orange", Color.orange),
        ("yellow", Color.yellow),
        ("green", Color.green),
        ("teal", Color.teal)
    ]
    
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
        showModeIndicator = true
        accentColorName = "blue"
        panelOpacity = 0.95
        showShortcutHints = true
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var spaceManager: SpaceManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Tab picker
            tabPicker
            
            Divider()
            
            // Content
            TabView(selection: $selectedTab) {
                generalTab
                    .tag(0)
                
                appearanceTab
                    .tag(1)
                
                aboutTab
                    .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 480, height: 420)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            Text("SpaceCommand Settings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var tabPicker: some View {
        HStack(spacing: 0) {
            TabButton(title: "General", icon: "gear", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Appearance", icon: "paintbrush", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "About", icon: "info.circle", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Keyboard") {
                    SettingsRow(
                        icon: "keyboard",
                        title: "Global Hotkey",
                        subtitle: "⌘⇧Space to activate"
                    ) {
                        Toggle("", isOn: $settings.hotkeyEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                }
                
                SettingsSection(title: "System") {
                    SettingsRow(
                        icon: "dock.rectangle",
                        title: "Show in Dock",
                        subtitle: "Display app icon in Dock"
                    ) {
                        Toggle("", isOn: $settings.showInDock)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    
                    Divider().padding(.leading, 44)
                    
                    SettingsRow(
                        icon: "power",
                        title: "Launch at Login",
                        subtitle: "Start automatically when you log in"
                    ) {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                }
                
                SettingsSection(title: "Mode") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Mode")
                                .font(.system(size: 13, weight: .medium))
                            Text(spaceManager.isYabaiMode ? "Using Yabai window manager" : "Using native macOS APIs")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(spaceManager.isYabaiMode ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(spaceManager.isYabaiMode ? "Yabai" : "Native")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            (spaceManager.isYabaiMode ? Color.green : Color.orange).opacity(0.15)
                        )
                        .clipShape(Capsule())
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private var appearanceTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Interface") {
                    SettingsRow(
                        icon: "tag",
                        title: "Mode Indicator",
                        subtitle: "Show yabai/native badge"
                    ) {
                        Toggle("", isOn: $settings.showModeIndicator)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    
                    Divider().padding(.leading, 44)
                    
                    SettingsRow(
                        icon: "command",
                        title: "Shortcut Hints",
                        subtitle: "Show keyboard shortcuts in list"
                    ) {
                        Toggle("", isOn: $settings.showShortcutHints)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                }
                
                SettingsSection(title: "Accent Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(AppSettings.availableColors, id: \.0) { name, color in
                            ColorButton(
                                color: color,
                                isSelected: settings.accentColorName == name
                            ) {
                                settings.accentColorName = name
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                
                SettingsSection(title: "Panel Opacity") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transparency")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text("\(Int(settings.panelOpacity * 100))%")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $settings.panelOpacity, in: 0.5...1.0, step: 0.05)
                            .accentColor(.accentColor)
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                
                // Reset button
                HStack {
                    Spacer()
                    Button(action: { settings.resetToDefaults() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private var aboutTab: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App icon and name
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "square.grid.3x3.topleft.filled")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(AppInfo.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Version \(AppInfo.fullVersion)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Info grid
            VStack(spacing: 12) {
                InfoRow(label: "Build", value: AppInfo.build)
                InfoRow(label: "System", value: AppInfo.systemInfo)
                InfoRow(label: "Bundle ID", value: AppInfo.bundleId)
            }
            .padding(16)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Copyright
            Text(AppInfo.copyright)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.accentColor.opacity(0.1) : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.primary.opacity(0.03))
            .cornerRadius(10)
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            trailing
        }
        .padding(12)
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
