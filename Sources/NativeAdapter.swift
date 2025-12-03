import Cocoa
import Foundation
import Security
import ServiceManagement

/// Native macOS adapter using private CoreGraphics APIs for Space management
/// This allows SpaceCommand to work without Yabai installed
class NativeAdapter: SpaceService {
    private let conn = _CGSDefaultConnection()
    private let defaults = UserDefaults.standard
    private let spaceNamesKey = "nativeSpaceNames"
    private var hasAccessibilityPermission: Bool = false
    private var hasAppleEventsPermission: Bool = false

    // MARK: - Permission Management

    /// Check and update permission status
    func checkPermissions() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasAppleEventsPermission = checkAppleEventsPermission()
    }

    /// Public properties to check permission status
    public var hasAccessibilityPermissionPublic: Bool {
        return hasAccessibilityPermission
    }

    public var hasAppleEventsPermissionPublic: Bool {
        return hasAppleEventsPermission
    }

    /// Check if Accessibility permission is granted
    private func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        return accessibilityEnabled
    }

    /// Check if Apple Events permission is granted
    private func checkAppleEventsPermission() -> Bool {
        let script = """
            tell application "System Events"
                return true
            end tell
            """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }

    /// Prompt user to grant Accessibility permission
    func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText =
            "SpaceCommand needs permission to control your computer to switch spaces. Please grant Accessibility permission in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// Prompt user to grant Apple Events permission
    func requestAppleEventsPermission() {
        let alert = NSAlert()
        alert.messageText = "Apple Events Permission Required"
        alert.informativeText =
            "SpaceCommand needs permission to use Apple Events for space switching. Please grant permission when prompted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Try Again")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let script = """
                tell application "System Events"
                    activate
                    key code 18 using control down
                end tell
                """

            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if error != nil {
                    // Permission likely denied, inform user
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Permission Denied"
                    errorAlert.informativeText =
                        "Please grant SpaceCommand permission in System Preferences > Security & Privacy > Privacy > Accessibility"
                    errorAlert.runModal()
                }
            }
        }
    }

    var isAvailable: Bool {
        // Check permissions first
        checkPermissions()

        // Try to get spaces - if this works, native mode is functional
        let spaces = getSpaces()
        let basicAvailability = !spaces.isEmpty

        // We need at least one permission type to be available
        return basicAvailability && (hasAccessibilityPermission || hasAppleEventsPermission)
    }

    var canPerformOperations: Bool {
        checkPermissions()
        return hasAccessibilityPermission || hasAppleEventsPermission
    }

    func getSpaces() -> [Space] {
        guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [NSDictionary] else {
            return []
        }

        var allSpaces: [Space] = []
        var spaceIndex = 0
        let savedNames = loadSpaceNames()

        for display in displays {
            guard let currentSpace = display["Current Space"] as? [String: Any],
                let spaces = display["Spaces"] as? [[String: Any]],
                let displayID = display["Display Identifier"] as? String
            else {
                continue
            }

            let activeSpaceID = currentSpace["ManagedSpaceID"] as? Int ?? -1
            var desktopNumber = 0

            for spaceDict in spaces {
                let spaceID = spaceDict["ManagedSpaceID"] as? Int ?? 0
                let spaceIDString = String(spaceID)
                let isFullScreen = spaceDict["TileLayoutManager"] as? [String: Any] != nil
                let isCurrent = activeSpaceID == spaceID

                // Only count non-fullscreen spaces as desktop numbers
                if !isFullScreen {
                    desktopNumber += 1
                }

                spaceIndex += 1

                // Determine the label/name
                var label: String? = savedNames[spaceIDString]

                // For fullscreen spaces, try to get the app name if no saved name
                if label == nil && isFullScreen {
                    if let pid = spaceDict["pid"] as? pid_t,
                        let app = NSRunningApplication(processIdentifier: pid),
                        let name = app.localizedName
                    {
                        label = name
                    }
                }

                let space = Space(
                    id: spaceIDString,
                    index: isFullScreen ? spaceIndex : desktopNumber,
                    label: label,
                    isCurrent: isCurrent,
                    uuid: nil,
                    displayId: displayID,
                    isFullScreen: isFullScreen
                )

                allSpaces.append(space)
            }
        }

        return allSpaces
    }

    func getCurrentSpace() -> Space? {
        return getSpaces().first { $0.isCurrent }
    }

    func switchTo(space: Space) {
        print("NativeAdapter.switchTo called for space \(space.index) (id: \(space.id), fullscreen: \(space.isFullScreen))")
        
        // Check permissions first
        checkPermissions()
        print("NativeAdapter: accessibility=\(hasAccessibilityPermission), appleEvents=\(hasAppleEventsPermission)")

        // If no permissions available, prompt user
        if !hasAccessibilityPermission && !hasAppleEventsPermission {
            print("NativeAdapter: No permissions, requesting...")
            requestAccessibilityPermission()
            return
        }

        // Native space switching using keyboard simulation
        // macOS doesn't expose a direct API to switch spaces, so we use:
        // 1. Mission Control keyboard shortcuts (Ctrl + number)
        // 2. Or AppleScript/Accessibility API

        // Method 1: Use keyboard simulation for Ctrl+Number (works for spaces 1-10)
        // Only use if we have accessibility permission
        if hasAccessibilityPermission && !space.isFullScreen && space.index >= 1
            && space.index <= 10
        {
            print("NativeAdapter: Using keyboard simulation for space \(space.index)")
            simulateSpaceSwitch(to: space.index)
            return
        }

        // Method 2: Use AppleScript as fallback for all spaces
        // Use if we have Apple Events permission or keyboard simulation failed
        if hasAppleEventsPermission {
            print("NativeAdapter: Using AppleScript for space \(space.index)")
            switchViaAppleScript(spaceIndex: space.index, isFullScreen: space.isFullScreen)
            return
        }

        // If we get here, we don't have any working permission
        print("NativeAdapter: No permissions available for space switching")
        requestAccessibilityPermission()
    }

    func renameSpace(space: Space, to name: String) {
        // Native macOS doesn't support renaming spaces directly
        // We store names locally in UserDefaults
        var savedNames = loadSpaceNames()
        savedNames[space.id] = name.isEmpty ? nil : name
        saveSpaceNames(savedNames)
    }

    // MARK: - Private Methods

    private func loadSpaceNames() -> [String: String] {
        guard let data = defaults.data(forKey: spaceNamesKey),
            let names = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return names
    }

    private func saveSpaceNames(_ names: [String: String]) {
        if let data = try? JSONEncoder().encode(names) {
            defaults.set(data, forKey: spaceNamesKey)
        }
    }

    /// Simulate Ctrl+Number keyboard shortcut to switch spaces
    private func simulateSpaceSwitch(to index: Int) {
        // Map space index to key code
        // Space 1 = key 18 (1), Space 2 = key 19 (2), etc.
        let keyCodes: [Int: CGKeyCode] = [
            1: 18,  // 1
            2: 19,  // 2
            3: 20,  // 3
            4: 21,  // 4
            5: 23,  // 5
            6: 22,  // 6
            7: 26,  // 7
            8: 28,  // 8
            9: 25,  // 9
            10: 29,  // 0 (for space 10)
        ]

        guard let keyCode = keyCodes[index] else {
            print("NativeAdapter: Invalid space index \(index), cannot simulate key press")
            return
        }

        print("NativeAdapter: Simulating Ctrl+\(index) (keyCode: \(keyCode))")

        let source = CGEventSource(stateID: .hidSystemState)

        // Create key down event with Control modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = .maskControl
            keyDown.post(tap: .cghidEventTap)
            print("NativeAdapter: Posted key down event")
        } else {
            print("NativeAdapter: Failed to create key down event")
        }

        // Small delay between key down and key up
        usleep(50000)

        // Create key up event
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = .maskControl
            keyUp.post(tap: .cghidEventTap)
            print("NativeAdapter: Posted key up event")
        } else {
            print("NativeAdapter: Failed to create key up event")
        }
    }

    /// Use AppleScript to switch spaces via Mission Control
    private func switchViaAppleScript(spaceIndex: Int, isFullScreen: Bool) {
        // This requires Accessibility permissions
        // Uses System Events to trigger Mission Control and select the space

        let script: String
        if isFullScreen {
            // For fullscreen apps, we can try to activate by index
            script = """
                tell application "System Events"
                    key code 126 using control down
                    delay 0.3
                    key code \(spaceIndex + 17)
                    delay 0.1
                    key code 53
                end tell
                """
        } else {
            // For regular desktops, use Ctrl + number if in range
            if spaceIndex >= 1 && spaceIndex <= 10 {
                let keyCode = spaceIndex == 10 ? 29 : 17 + spaceIndex
                script = """
                    tell application "System Events"
                        key code \(keyCode) using control down
                    end tell
                    """
            } else {
                // For spaces beyond 10, use Mission Control navigation
                script = """
                    tell application "System Events"
                        key code 126 using control down
                        delay 0.3
                        repeat \(spaceIndex - 1) times
                            key code 124
                            delay 0.1
                        end repeat
                        key code 36
                    end tell
                    """
            }
        }

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("NativeAdapter: AppleScript error: \(error)")
            }
        }
    }
}
