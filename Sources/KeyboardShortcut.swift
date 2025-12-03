import Foundation

struct KeyboardShortcut: Codable, Equatable {
    var key: UInt32
    var modifiers: [String]  // "cmd", "shift", "option", "control"

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

    private func keyToString() -> String {
        switch key {
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 117: return "⌦"
        case 53: return "Esc"
        case 123: return "←"
        case 124: return "→"
        case 126: return "↑"
        case 125: return "↓"
        case 115: return "Home"
        case 119: return "End"
        case 116: return "PgUp"
        case 121: return "PgDn"

        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 105: return "F13"
        case 107: return "F14"
        case 113: return "F15"
        case 106: return "F16"
        case 64: return "F17"
        case 79: return "F18"
        case 80: return "F19"
        case 81: return "F20"

        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 6: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 13: return "Z"

        case 29: return "0"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"

        case 43: return ","
        case 47: return "."
        case 44: return "/"
        case 41: return ";"
        case 39: return "'"
        case 33: return "["
        case 30: return "]"
        case 42: return "\\"
        case 24: return "="
        case 27: return "-"
        case 50: return "`"
        default: return "Key\(key)"
        }
    }

    static let cmdShiftSpace = KeyboardShortcut(key: UInt32(49), modifiers: ["cmd", "shift"])

    init(key: UInt32, modifiers: [String]) {
        self.key = key
        self.modifiers = modifiers
    }
}
