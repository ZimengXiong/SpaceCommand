import Foundation

/// Adapter for Yabai window manager integration
class YabaiAdapter: SpaceService {
    private let yabaiPath: String?

    init() {
        self.yabaiPath = Self.findYabai()
    }

    var isAvailable: Bool {
        guard yabaiPath != nil else { return false }
        let result = shell("\(yabaiPath!) -m query --spaces")
        return result != nil && !result!.isEmpty
    }

    var canPerformOperations: Bool {
        // Yabai can always perform operations if it's available
        return isAvailable
    }

    func getSpaces() -> [Space] {
        guard let yabai = yabaiPath,
            let output = shell("\(yabai) -m query --spaces"),
            let data = output.data(using: .utf8)
        else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let yabaiSpaces = try decoder.decode([YabaiSpace].self, from: data)
            return yabaiSpaces.map { ySpace in
                Space(
                    id: "\(ySpace.id)",
                    index: ySpace.index,
                    label: ySpace.label.isEmpty ? nil : ySpace.label,
                    isCurrent: ySpace.hasFocus,
                    uuid: ySpace.uuid
                )
            }
        } catch {
            print("Failed to parse yabai spaces: \(error)")
            return []
        }
    }

    func getCurrentSpace() -> Space? {
        return getSpaces().first { $0.isCurrent }
    }

    func switchTo(space: Space) {
        guard let yabai = yabaiPath else { return }

        // Try switching by label first if available, then by index
        if let label = space.label, !label.isEmpty {
            // Escape quotes in label if needed
            let escapedLabel = label.replacingOccurrences(of: "\"", with: "\\\"")
            _ = shell("\(yabai) -m space --focus \"\(escapedLabel)\"")
        } else {
            _ = shell("\(yabai) -m space --focus \(space.index)")
        }
    }

    func renameSpace(space: Space, to name: String) {
        guard let yabai = yabaiPath else { return }
        // Escape the name for shell - specifically double quotes and spaces if needed,
        // but since we wrap in quotes, we mainly need to escape quotes.
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        _ = shell("\(yabai) -m space \(space.index) --label \"\(escapedName)\"")
    }

    // MARK: - Private Helpers

    private static func findYabai() -> String? {
        // Common paths for yabai
        let paths = [
            "/usr/local/bin/yabai",
            "/opt/homebrew/bin/yabai",
            "/run/current-system/sw/bin/yabai",  // NixOS
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "which yabai"]
        task.launchPath = "/bin/bash"
        task.standardInput = nil

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8), !result.isEmpty {
                return result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
        } catch {}

        return nil
    }

    private func shell(_ command: String) -> String? {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.standardInput = nil

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// MARK: - Yabai JSON Models

private struct YabaiSpace: Codable {
    let id: Int
    let uuid: String
    let index: Int
    let label: String
    let hasFocus: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case index
        case label
        case hasFocus = "has-focus"
    }
}
