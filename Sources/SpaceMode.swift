import Foundation

enum SpaceMode: String, Codable, CaseIterable {
    case auto = "auto"
    case yabai = "yabai"
    case native = "native"

    var displayName: String {
        switch self {
        case .auto: return "Auto (Yabai if available)"
        case .yabai: return "Yabai"
        case .native: return "Native macOS"
        }
    }
}
