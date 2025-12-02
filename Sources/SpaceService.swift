import Foundation

/// Represents a virtual desktop/space
struct Space: Identifiable, Equatable {
    let id: String
    let index: Int
    let label: String?
    let isCurrent: Bool
    let uuid: String?
    
    var displayName: String {
        if let label = label, !label.isEmpty {
            return label
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
}
