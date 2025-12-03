import Foundation

struct Space: Identifiable, Equatable {
    let id: String
    let index: Int
    let label: String?
    let isCurrent: Bool
    let uuid: String?
    let displayId: String?
    let isFullScreen: Bool

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

protocol SpaceService {
    func getSpaces() -> [Space]
    func getCurrentSpace() -> Space?
    func switchTo(space: Space)
    func renameSpace(space: Space, to name: String)
    var isAvailable: Bool { get }

    var canPerformOperations: Bool { get }
}
