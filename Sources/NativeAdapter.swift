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
    private let permissionsCheckedKey = "permissionsInitiallyChecked"
    private var hasAccessibilityPermission: Bool = false
    private var hasAppleEventsPermission: Bool = false

    // MARK: - Permission Management

    /// Check and update permission status
    func checkPermissions() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasAppleEventsPermission = checkAppleEventsPermission()
        print(
            "NativeAdapter: Permissions check - Accessibility: \(hasAccessibilityPermission), Automation: \(hasAppleEventsPermission)"
        )
    }

    /// Request all required permissions on first launch
    /// Call this from the app delegate or on first panel show
    func ensurePermissionsOnFirstLaunch() {
        checkPermissions()

        print(
            "NativeAdapter: ensurePermissionsOnFirstLaunch - Accessibility: \(hasAccessibilityPermission), Automation: \(hasAppleEventsPermission)"
        )

        // If Automation permission is missing, trigger it first (it shows a system prompt)
        if !hasAppleEventsPermission {
            print("NativeAdapter: Triggering System Events permission prompt...")
            triggerSystemEventsPermissionPrompt()
        }

        // If Accessibility permission is missing, show our dialog
        if !hasAccessibilityPermission {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
                SpaceCommand needs Accessibility permission to simulate keyboard shortcuts for switching spaces.

                Click "Open System Settings" to add SpaceCommand to the Accessibility list.
                """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                // Trigger the system prompt
                let options: NSDictionary = [
                    kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
                ]
                AXIsProcessTrustedWithOptions(options)
            }
        }

        
        checkPermissions()
    }

    /// Trigger the System Events permission prompt by running an AppleScript
    /// This will cause macOS to show the "SpaceCommand wants to control System Events" dialog
    private func triggerSystemEventsPermissionPrompt() {
        // This AppleScript will trigger the Automation permission prompt for System Events
        let script = """
            tell application "System Events"
                set frontApp to name of first application process whose frontmost is true
                return frontApp
            end tell
            """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let error = error {
                print(
                    "NativeAdapter: AppleScript error (expected if permission not yet granted): \(error)"
                )
                // Error -1743 means user denied permission
                // Error -600 means app not running (System Events needs to launch)
            } else {
                print(
                    "NativeAdapter: AppleScript executed successfully, result: \(result.stringValue ?? "nil")"
                )
                hasAppleEventsPermission = true
            }
        }
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
            "SpaceCommand needs Accessibility permission to simulate keyboard shortcuts for switching spaces.\n\nPlease add SpaceCommand to the list in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Use the prompt option to trigger the system dialog
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options)

            // Also open the preferences pane
            if let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// Prompt user to grant Apple Events/Automation permission
    func requestAppleEventsPermission() {
        let alert = NSAlert()
        alert.messageText = "Automation Permission Required"
        alert.informativeText =
            "SpaceCommand needs permission to control System Events for space switching.\n\nPlease grant Automation permission in System Settings > Privacy & Security > Automation, then enable 'System Events' for SpaceCommand."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Try Now")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open Automation preferences
            if let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
            ) {
                NSWorkspace.shared.open(url)
            }
        } else if response == .alertSecondButtonReturn {
            // Try to trigger the permission prompt by running an AppleScript
            let script = """
                tell application "System Events"
                    return name of first process
                end tell
                """

            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if error != nil {
                    // Permission denied - show follow-up
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Permission Needed"
                    errorAlert.informativeText =
                        "macOS should have prompted you for Automation permission. If you denied it, please go to System Settings > Privacy & Security > Automation and enable 'System Events' for SpaceCommand."
                    errorAlert.addButton(withTitle: "Open System Settings")
                    errorAlert.addButton(withTitle: "OK")

                    if errorAlert.runModal() == .alertFirstButtonReturn {
                        if let url = URL(
                            string:
                                "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
                        ) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                } else {
                    // Permission was granted!
                    checkPermissions()
                }
            }
        }
    }

    var isAvailable: Bool {
        
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
        print(
            "NativeAdapter.switchTo called for space \(space.index) (id: \(space.id), fullscreen: \(space.isFullScreen))"
        )

        
        checkPermissions()
        print(
            "NativeAdapter: accessibility=\(hasAccessibilityPermission), appleEvents=\(hasAppleEventsPermission)"
        )

        // Log bundle info for debugging
        if let bundleID = Bundle.main.bundleIdentifier {
            print("NativeAdapter: Running as bundle: \(bundleID)")
        }
        print("NativeAdapter: Executable path: \(Bundle.main.executablePath ?? "unknown")")

        // If no permissions available, prompt user
        if !hasAccessibilityPermission && !hasAppleEventsPermission {
            print("NativeAdapter: No permissions, requesting...")
            requestAccessibilityPermission()
            return
        }

        // Native space switching using keyboard simulation
        // macOS doesn't expose a direct API to switch spaces, so we use:
        // 1. CGEvent keyboard simulation (preferred - works best from command line/background)
        // 2. AppleScript as fallback (works when System Events has focus control)

        
        let currentSpaceBefore = getCurrentSpace()
        print("NativeAdapter: Current space before switch: \(currentSpaceBefore?.index ?? -1)")

        
        if hasAccessibilityPermission && !space.isFullScreen && space.index >= 1
            && space.index <= 10
        {
            print("NativeAdapter: Using CGEvent keyboard simulation for space \(space.index)")

            
            for attempt in 1...3 {
                print("NativeAdapter: CGEvent attempt \(attempt)")
                let success = simulateSpaceSwitchWithCGEvent(to: space.index)
                if success {
                    // Give macOS time to process the event
                    usleep(150000)  // 150ms

                    // Verify the switch happened
                    let currentSpaceAfter = getCurrentSpace()
                    print(
                        "NativeAdapter: Current space after CGEvent: \(currentSpaceAfter?.index ?? -1)"
                    )

                    if currentSpaceAfter?.index == space.index {
                        print("NativeAdapter: CGEvent switch verified successful!")
                        return
                    }
                    print(
                        "NativeAdapter: CGEvent posted but switch not verified, attempt \(attempt)")
                }
                usleep(100000)  // 100ms between attempts
            }
            print("NativeAdapter: CGEvent failed after 3 attempts, trying AppleScript fallback")
        }

        
        if hasAppleEventsPermission {
            for attempt in 1...2 {
                print("NativeAdapter: AppleScript attempt \(attempt) for space \(space.index)")
                switchViaAppleScript(spaceIndex: space.index, isFullScreen: space.isFullScreen)

                // Give time for AppleScript to execute
                usleep(200000)  // 200ms

                // Verify the switch
                let currentSpaceAfter = getCurrentSpace()
                print(
                    "NativeAdapter: Current space after AppleScript: \(currentSpaceAfter?.index ?? -1)"
                )

                if currentSpaceAfter?.index == space.index {
                    print("NativeAdapter: AppleScript switch verified successful!")
                    return
                }
                usleep(100000)  // 100ms between attempts
            }
        }

        
        print("NativeAdapter: All switching methods failed")
        if !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
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

    /// Simulate Ctrl+Number keyboard shortcut to switch spaces using CGEvent
    /// Returns true if the event was posted successfully
    private func simulateSpaceSwitchWithCGEvent(to index: Int) -> Bool {
        // macOS key codes for number keys (these are NOT sequential!)
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
            return false
        }

        print(
            "NativeAdapter: Simulating Ctrl+\(index == 10 ? "0" : String(index)) (keyCode: \(keyCode))"
        )

        // Try different event source states - hidSystemState often works better for GUI apps
        let sourceStates: [CGEventSourceStateID] = [.hidSystemState, .combinedSessionState]

        for sourceState in sourceStates {
            print("NativeAdapter: Trying CGEventSource state: \(sourceState.rawValue)")

            guard let source = CGEventSource(stateID: sourceState) else {
                print(
                    "NativeAdapter: Failed to create event source with state \(sourceState.rawValue)"
                )
                continue
            }

            // Create key down event with Control modifier
            guard
                let keyDown = CGEvent(
                    keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
            else {
                print("NativeAdapter: Failed to create key down event")
                continue
            }

            keyDown.flags = .maskControl

            // Create key up event
            guard
                let keyUp = CGEvent(
                    keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            else {
                print("NativeAdapter: Failed to create key up event")
                continue
            }

            keyUp.flags = .maskControl

            // Try cghidEventTap first (lowest level, works best for system hotkeys)
            print("NativeAdapter: Posting to cghidEventTap")
            keyDown.post(tap: .cghidEventTap)
            usleep(30000)  // 30ms
            keyUp.post(tap: .cghidEventTap)

            print(
                "NativeAdapter: Posted key events with sourceState \(sourceState.rawValue) to cghidEventTap"
            )
            return true
        }

        print("NativeAdapter: All CGEvent approaches failed")
        return false
    }

    /// Use AppleScript to switch spaces via Mission Control
    private func switchViaAppleScript(spaceIndex: Int, isFullScreen: Bool) {
        // This requires Accessibility permissions
        // Uses System Events to trigger Mission Control and select the space

        // macOS key codes for number keys (these are NOT sequential!)
        let numberKeyCodes: [Int: Int] = [
            1: 18,  // '1'
            2: 19,  // '2'
            3: 20,  // '3'
            4: 21,  // '4'
            5: 23,  // '5'
            6: 22,  // '6'
            7: 26,  // '7'
            8: 28,  // '8'
            9: 25,  // '9'
            10: 29,  // '0'
        ]

        let script: String
        if isFullScreen {
            // For fullscreen apps, we can try to activate by index
            script = """
                tell application "System Events"
                    key code 126 using control down
                    delay 0.3
                    key code \(numberKeyCodes[spaceIndex] ?? 18)
                    delay 0.1
                    key code 53
                end tell
                """
        } else {
            // For regular desktops, use Ctrl + number if in range
            if spaceIndex >= 1 && spaceIndex <= 10, let keyCode = numberKeyCodes[spaceIndex] {
                print(
                    "NativeAdapter: AppleScript using key code \(keyCode) for space \(spaceIndex)")
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

        print("NativeAdapter: Executing AppleScript: \(script)")
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let error = error {
                print("NativeAdapter: AppleScript error: \(error)")
            } else {
                print("NativeAdapter: AppleScript executed successfully, result: \(result)")
            }
        } else {
            print("NativeAdapter: Failed to create AppleScript")
        }
    }
}
