import Foundation

/// Represents a virtual desktop/space
struct Space: Identifiable, Equatable {
    let id: String
    let index: Int
    let label: String?
    let isCurrent: Bool
    let uuid: String?
    let displayId: String?
    let isFullScreen: Bool

    /// Initialize a space (with defaults for optional native-mode properties)
    init(
        id: String, index: Int, label: String?, isCurrent: Bool, uuid: String?,
        displayId: String? = nil, isFullScreen: Bool = false
    ) {
        self.id = id
        self.index = index
        self.label = label
        self.isCurrent = isCurrent
        self.uuid = uuid
        self.displayId = displayId
        self.isFullScreen = isFullScreen
    }

    var displayName: String {
        if let label = label, !label.isEmpty {
            return label
        }
        if isFullScreen {
            return "Fullscreen \(index)"
        }
        return "Space \(index)"
    }
}

/// Protocol defining space management operations
protocol SpaceService {
    func getSpaces() -> [Space]
    func getCurrentSpace() -> Space?
    func switchTo(space: Space)
    func renameSpace(space: Space, to name: String)
    var isAvailable: Bool { get }

    /// Check if the adapter can perform operations (has necessary permissions)
    var canPerformOperations: Bool { get }
}


