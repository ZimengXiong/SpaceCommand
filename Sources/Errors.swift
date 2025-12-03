import Foundation

enum SpaceCommandError: Error, LocalizedError {
    case yabaiNotFound
    case yabaiCommandFailed(String)
    case permissionDenied(String)
    case spaceNotFound(Int)
    case invalidHotkey
    case shellCommandFailed(String, String)
    case nativeApiUnavailable
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .yabaiNotFound:
            return "Yabai window manager is not installed or not found in PATH"
        case .yabaiCommandFailed(let command):
            return "Yabai command failed: \(command)"
        case .permissionDenied(let permission):
            return "Required permission denied: \(permission)"
        case .spaceNotFound(let index):
            return "Space with index \(index) not found"
        case .invalidHotkey:
            return "Invalid hotkey configuration"
        case .shellCommandFailed(let command, let error):
            return "Shell command failed '\(command)': \(error)"
        case .nativeApiUnavailable:
            return "Native macOS API is not available on this system"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .yabaiNotFound:
            return "Install Yabai using: brew install yabai"
        case .permissionDenied("Accessibility"):
            return
                "Grant Accessibility permission in System Settings > Privacy & Security > Accessibility"
        case .permissionDenied("Automation"):
            return
                "Grant Automation permission in System Settings > Privacy & Security > Automation for System Events"
        case .spaceNotFound(let index):
            return "Check if space \(index) exists and try refreshing the space list"
        case .invalidHotkey:
            return
                "Choose a hotkey combination with at least one modifier key (Cmd, Option, Control, or Shift)"
        case .nativeApiUnavailable:
            return "This feature requires macOS 10.15 or later"
        default:
            return nil
        }
    }
}

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"

}

class Logger {
    static let shared = Logger()

    private init() {}

    func log(
        _ message: String, level: LogLevel = .debug, file: String = #file,
        function: String = #function, line: Int = #line
    ) {
        let timestamp = DateFormatter.currentTime.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage =
            "\(timestamp) [\(level.rawValue)] \(fileName):\(line) - \(function): \(message)"

        Swift.print(logMessage)
    }

    func debug(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    func error(
        _ error: Error, file: String = #file, function: String = #function, line: Int = #line
    ) {
        if let spaceError = error as? SpaceCommandError {
            log(
                spaceError.errorDescription ?? "Unknown error", level: .error, file: file,
                function: function, line: line)

            if let suggestion = spaceError.recoverySuggestion {
                log(
                    "Suggestion: \(suggestion)", level: .info, file: file, function: function,
                    line: line)
            }
        } else {
            log(
                "Unexpected error: \(error.localizedDescription)", level: .error, file: file,
                function: function, line: line)
        }
    }
}

extension DateFormatter {
    static let currentTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
