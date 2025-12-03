import SwiftUI

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

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

            VStack(spacing: 8) {
                Text(AppInfo.name)
                    .font(.title2.weight(.bold))

                Text("Version \(AppInfo.fullVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

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

struct AppInfo {
    static let version = "1.0.0"
    static let build = "1"
    static let name = "SpaceCommand"
    static let bundleId = "com.SpaceCommand.SpaceCommand"

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
