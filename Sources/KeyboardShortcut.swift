import Foundation

struct KeyboardShortcut: Codable, Equatable {
    var key: UInt32
    var modifiers: [String]

    var displayString: String {
        var result = ""
        if modifiers.contains("cmd") { result += "⌘" }
        if modifiers.contains("shift") { result += "⇧" }
        if modifiers.contains("option") { result += "⌥" }
        if modifiers.contains("control") { result += "⌃" }

        let keyChar = keyToString()
        result += keyChar
        return result
    }

    private static let keyMapping: [UInt32: String] = [
        // Special keys
        49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 117: "⌦", 53: "Esc",
        123: "←", 124: "→", 126: "↑", 125: "↓", 115: "Home", 119: "End",
        116: "PgUp", 121: "PgDn",
        // F-Keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17", 79: "F18",
        80: "F19", 81: "F20",
        // Letters
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
        34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
        12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 6: "W", 7: "X",
        16: "Y", 13: "Z",
        // Numbers
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6",
        26: "7", 28: "8", 25: "9",
        // Symbols
        43: ",", 47: ".", 44: "/", 41: ";", 39: "'", 33: "[", 30: "]", 42: "\\",
        24: "=", 27: "-", 50: "`",
    ]

    private func keyToString() -> String {
        if let specialKey = Self.keyMapping[key] {
            return specialKey
        }
        return "Key \(key)"
    }

    static let cmdShiftSpace = KeyboardShortcut(key: UInt32(49), modifiers: ["cmd", "shift"])

    init(key: UInt32, modifiers: [String]) {
        self.key = key
        self.modifiers = modifiers
    }
}
