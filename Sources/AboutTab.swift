import SwiftUI

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
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
    static let version = "0.1.1"
    static let build = "32"
    static let name = "SpaceCommand"
    static let bundleId = "com.ZimengXiong.SpaceCommand"

    static var fullVersion: String {
        "\(version) (\(build))"
    }

    static var copyright: String {
        "© 2025 Zimeng Xiong"
    }

    static var systemInfo: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "macOS \(osVersion)"
    }
}
