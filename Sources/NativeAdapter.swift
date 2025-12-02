import Foundation
import CoreGraphics
import Carbon

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
        // Get current space using private API
        let currentSpaceIndex = getCurrentSpaceIndex()
        
        // Get total number of spaces
        let spaceCount = getSpaceCount()
        let savedNames = persistenceManager.loadSpaceNames()
        
        var spaces: [Space] = []
        for i in 1...max(spaceCount, 1) {
            let label = savedNames["\(i)"]
            spaces.append(Space(
                id: "\(i)",
                index: i,
                label: label,
                isCurrent: i == currentSpaceIndex,
                uuid: nil
            ))
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
            9: 0x19   // 9
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
