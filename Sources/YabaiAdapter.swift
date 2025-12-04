import Foundation

class YabaiAdapter: SpaceService {
    private let yabaiPath: String?

    init() {
        self.yabaiPath = Self.findYabai()
    }

    private let logger = Logger.shared

    var isAvailable: Bool {
        guard yabaiPath != nil else { return false }
        let result = shell("\(yabaiPath!) -m query --spaces")
        return result != nil && !result!.isEmpty
    }

    var canPerformOperations: Bool { return isAvailable }

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
                let spaceId = String(ySpace.id)
                var finalLabel = AppSettings.shared.getLabel(for: spaceId)

                if finalLabel == nil && !ySpace.label.isEmpty {
                    finalLabel = ySpace.label
                    DispatchQueue.main.async {
                        AppSettings.shared.setLabel(for: spaceId, label: ySpace.label)
                    }
                }

                return Space(
                    id: spaceId,
                    index: ySpace.index,
                    label: finalLabel,
                    isCurrent: ySpace.hasFocus,
                    uuid: ySpace.uuid
                )
            }
        } catch {
            logger.error("Failed to parse yabai spaces: \(error)")
            return []
        }
    }

    func getCurrentSpace() -> Space? {
        return getSpaces().first { $0.isCurrent }
    }

    func switchTo(space: Space) {
        guard let yabai = yabaiPath else {
            logger.error("YabaiAdapter: yabaiPath is nil, cannot switch spaces")
            return
        }

        logger.debug(
            "YabaiAdapter: Attempting to switch to space \(space.index) with label '\(space.label ?? "nil")'"
        )

        logger.debug("YabaiAdapter: Using index-based switch to \(space.index)")
        let result = shell("\(yabai) -m space --focus \(space.index)")

        if result == nil || result?.isEmpty == false {
            logger.error(
                "YabaiAdapter: Index-based switch failed or returned unexpected result: \(result ?? "nil")"
            )

            if let label = space.label, !label.isEmpty {
                let escapedLabel = label.replacingOccurrences(of: "\"", with: "\\\"")
                logger.debug(
                    "YabaiAdapter: Trying label-based fallback switch to '\(escapedLabel)'")
                let labelResult = shell("\(yabai) -m space --focus \"\(escapedLabel)\"")
                if labelResult == nil || labelResult?.isEmpty == false {
                    logger.error(
                        "YabaiAdapter: Label-based switch also failed: \(labelResult ?? "nil")")
                }
            }
        }
    }

    func renameSpace(space: Space, to name: String) {
        AppSettings.shared.setLabel(for: space.id, label: name)

        guard let yabai = yabaiPath else { return }

        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        _ = shell("\(yabai) -m space \(space.index) --label \"\(escapedName)\"")
    }

    private static func findYabai() -> String? {
        let paths = [
            "/usr/local/bin/yabai",
            "/opt/homebrew/bin/yabai",
            "/run/current-system/sw/bin/yabai",
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
        } catch {
            Logger.shared.debug("YabaiAdapter: failed to run 'which yabai': \(error)")
        }

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
