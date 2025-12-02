import Carbon
import CoreGraphics
import Foundation

/// Native adapter using private CoreGraphics APIs
class NativeAdapter: SpaceService {
    private let persistenceManager: PersistenceManager
    private let keyboardSimulator = KeyboardSimulator()

    init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }

    var isAvailable: Bool {
        // Native mode is always available (fallback)
        return true
    }

    func getSpaces() -> [Space] {
        // Get total number of spaces and current space info
        let spaceCount = getSpaceCount()
        let savedNames = persistenceManager.loadSpaceNames()
        let currentSpaceID = getCurrentSpaceID()

        // Get space IDs to map them correctly
        let spaceIDs = getSpaceIDs()

        var spaces: [Space] = []
        for i in 1...max(spaceCount, 1) {
            let label = savedNames["\(i)"]
            // Check if this index's space ID matches the current space ID
            let spaceID = i <= spaceIDs.count ? spaceIDs[i - 1] : 0
            let isCurrent = spaceID == currentSpaceID || (spaceIDs.isEmpty && i == 1)

            spaces.append(
                Space(
                    id: "\(i)",
                    index: i,
                    label: label,
                    isCurrent: isCurrent,
                    uuid: nil
                ))
        }

        // If no space is marked as current, mark the first one
        if !spaces.contains(where: { $0.isCurrent }) && !spaces.isEmpty {
            spaces[0] = Space(
                id: spaces[0].id,
                index: spaces[0].index,
                label: spaces[0].label,
                isCurrent: true,
                uuid: spaces[0].uuid
            )
        }

        return spaces
    }

    func getCurrentSpace() -> Space? {
        return getSpaces().first { $0.isCurrent }
    }

    func switchTo(space: Space) {
        // Use keyboard simulation: Ctrl + Number
        keyboardSimulator.pressControlNumber(space.index)
    }

    func renameSpace(space: Space, to name: String) {
        persistenceManager.saveSpaceName(index: space.index, name: name)
    }

    // MARK: - Private API Calls

    private func getCurrentSpaceID() -> Int {
        let connection = _CGSDefaultConnection()

        // Try to get current space from managed display spaces
        if let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] {
            for display in displays {
                if let currentSpaceDict = display["Current Space"] as? [String: Any],
                    let spaceID = currentSpaceDict["ManagedSpaceID"] as? Int
                {
                    return spaceID
                }
            }
        }

        // Fallback to CGSGetWorkspace
        var workspace: Int32 = 0
        CGSGetWorkspace(connection, &workspace)
        return Int(workspace)
    }

    private func getSpaceIDs() -> [Int] {
        let connection = _CGSDefaultConnection()
        var spaceIDs: [Int] = []

        if let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] {
            for display in displays {
                if let spaces = display["Spaces"] as? [[String: Any]] {
                    for space in spaces {
                        if let spaceID = space["ManagedSpaceID"] as? Int {
                            spaceIDs.append(spaceID)
                        }
                    }
                }
            }
        }

        return spaceIDs
    }

    private func getCurrentSpaceIndex() -> Int {
        var workspace: Int32 = 0
        let connection = _CGSDefaultConnection()
        CGSGetWorkspace(connection, &workspace)
        // Convert to 1-based index
        return Int(workspace)
    }

    private func getSpaceCount() -> Int {
        // Try to get space count from managed display spaces
        let connection = _CGSDefaultConnection()

        if let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] {
            var totalSpaces = 0
            for display in displays {
                if let spaces = display["Spaces"] as? [[String: Any]] {
                    totalSpaces += spaces.count
                }
            }
            if totalSpaces > 0 {
                return totalSpaces
            }
        }

        // Fallback: assume at least 9 spaces (max ctrl+number)
        return 9
    }
}

/// Simulates keyboard events for space switching
class KeyboardSimulator {

    /// Press Ctrl + Number key to switch spaces
    func pressControlNumber(_ number: Int) {
        guard number >= 1 && number <= 9 else { return }

        // Key codes for numbers 1-9
        let keyCodes: [Int: CGKeyCode] = [
            1: 0x12,  // 1
            2: 0x13,  // 2
            3: 0x14,  // 3
            4: 0x15,  // 4
            5: 0x17,  // 5
            6: 0x16,  // 6
            7: 0x1A,  // 7
            8: 0x1C,  // 8
            9: 0x19,  // 9
        ]

        guard let keyCode = keyCodes[number] else { return }

        let source = CGEventSource(stateID: .hidSystemState)

        // Key down with Control modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = .maskControl
            keyDown.post(tap: .cghidEventTap)
        }

        // Small delay
        usleep(50000)  // 50ms

        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = .maskControl
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
