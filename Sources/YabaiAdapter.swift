import Foundation

class YabaiAdapter: SpaceService {
    private let yabaiPath: String?

    init() {
        self.yabaiPath = Self.findYabai()
    }

    private let logger = Logger.shared

    var isAvailable: Bool {
        get async {
            guard yabaiPath != nil else { return false }
            let result = await shell("\(yabaiPath!) -m query --spaces")
            return result != nil && !result!.isEmpty
        }
    }

    var canPerformOperations: Bool {
        get async { return await isAvailable }
    }

    func getSpaces() async -> [Space] {
        guard let yabai = yabaiPath,
            let output = await shell("\(yabai) -m query --spaces"),
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

    func getCurrentSpace() async -> Space? {
        return await getSpaces().first { $0.isCurrent }
    }

    func switchTo(space: Space) async {
        guard let yabai = yabaiPath else { return }

        let result = await shell("\(yabai) -m space --focus \(space.index)")

        if result == nil || result?.isEmpty == false {
            if let label = space.label, !label.isEmpty {
                let escapedLabel = label.replacingOccurrences(of: "\"", with: "\\\"")
                _ = await shell("\(yabai) -m space --focus \"\(escapedLabel)\"")
            }
        }
    }

    func renameSpace(space: Space, to name: String) async {
        AppSettings.shared.setLabel(for: space.id, label: name)

        guard let yabai = yabaiPath else { return }

        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        _ = await shell("\(yabai) -m space \(space.index) --label \"\(escapedName)\"")
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
            // Ignore - yabai not found
        }

        return nil
    }

    private func shell(_ command: String) async -> String? {
        return await withCheckedContinuation { continuation in
            let task = Process()
            let pipe = Pipe()

            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c", command]
            task.launchPath = "/bin/bash"
            task.standardInput = nil

            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)
                continuation.resume(returning: output)
            }

            do {
                try task.run()
            } catch {
                continuation.resume(returning: nil)
            }
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
