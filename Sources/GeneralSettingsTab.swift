import SwiftUI

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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Backends:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        BackendOptionButton(
                            name: "Yabai",
                            isAvailable: spaceManager.isYabaiAvailable,
                            isActive: spaceManager.activeAdapterName == "Yabai",
                            action: {
                                if spaceManager.isYabaiAvailable {
                                    settings.spaceMode = .yabai
                                }
                            }
                        )

                        BackendOptionButton(
                            name: "Native",
                            isAvailable: spaceManager.isNativeAvailable,
                            isActive: spaceManager.activeAdapterName == "Native",
                            action: {
                                settings.spaceMode = .native
                            }
                        )
                    }
                }
                .padding(.vertical, 4)

            } header: {
                Text("Space Backend")
            }

            Section {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            spaceManager.refreshSpaces()
        }
    }
}

struct BackendStatusIndicator: View {
    let name: String
    let isAvailable: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {

            Circle()
                .fill(isAvailable ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(name)
                .font(.subheadline)
                .foregroundColor(isAvailable ? .primary : .secondary)

            if isActive {
                Text("Active")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct BackendOptionButton: View {
    let name: String
    let isAvailable: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {

                Circle()
                    .fill(isAvailable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                Text(name)
                    .font(.subheadline)
                    .foregroundColor(isAvailable ? .primary : .secondary)

                if isActive {
                    Text("Active")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}
