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

    // MARK: - Initialization
    init() {
        defaults.register(defaults: [
            Keys.hotkeyEnabled: true,
            Keys.showInDock: false,
            Keys.launchAtLogin: false,
        ])

        self.hotkeyEnabled = defaults.bool(forKey: Keys.hotkeyEnabled)
        self.showInDock = defaults.bool(forKey: Keys.showInDock)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
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
            header
            Divider()
            tabPicker
            Divider()

            TabView(selection: $selectedTab) {
                generalTab
                    .tag(0)
                aboutTab
                    .tag(1)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 440, height: 380)
        .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 20))
                .foregroundColor(.accentColor)

            Text("Settings")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private var tabPicker: some View {
        HStack(spacing: 0) {
            TabButton(title: "General", icon: "gear", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "About", icon: "info.circle", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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

                    Divider().padding(.leading, 40)

                    SettingsRow(
                        icon: "power",
                        title: "Launch at Login",
                        subtitle: "Start automatically when you log in"
                    ) {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                }

                SettingsSection(title: "Yabai") {
                    SettingsRow(
                        icon: "rectangle.split.3x1",
                        title: "Yabai Status",
                        subtitle: spaceManager.isYabaiAvailable
                            ? "Connected" : "Not available"
                    ) {
                        Circle()
                            .fill(spaceManager.isYabaiAvailable ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                    }
                }

                HStack {
                    Spacer()
                    Button(action: { settings.resetToDefaults() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var aboutTab: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: 64, height: 64)

                    Image(systemName: "square.grid.3x3.topleft.filled")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(AppInfo.name)
                    .font(.system(size: 20, weight: .bold))

                Text("Version \(AppInfo.fullVersion)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                InfoRow(label: "Build", value: AppInfo.build)
                InfoRow(label: "System", value: AppInfo.systemInfo)
                InfoRow(label: "Bundle ID", value: AppInfo.bundleId)
            }
            .padding(14)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
            .padding(.horizontal, 32)

            Spacer()

            Text(AppInfo.copyright)
                .font(.system(size: 10))
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
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor.opacity(0.1) : Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                content
            }
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            trailing
        }
        .padding(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
