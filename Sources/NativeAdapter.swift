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
        print(
            "NativeAdapter.switchTo called for space \(space.index) (id: \(space.id), fullscreen: \(space.isFullScreen))"
        )

        // Check permissions first
        checkPermissions()
        print(
            "NativeAdapter: accessibility=\(hasAccessibilityPermission), appleEvents=\(hasAppleEventsPermission)"
        )

        // If no permissions available, prompt user
        if !hasAccessibilityPermission && !hasAppleEventsPermission {
            print("NativeAdapter: No permissions, requesting...")
            requestAccessibilityPermission()
            return
        }

        // Native space switching using keyboard simulation
        // macOS doesn't expose a direct API to switch spaces, so we use:
        // 1. Keyboard shortcuts (configured in settings, default: Ctrl+Number for 1-10, Ctrl+Option+Number for 11-20)
        // 2. Or AppleScript/Accessibility API

        // Method 1: Use keyboard simulation for spaces 1-20 (configurable shortcuts)
        // Only use if we have accessibility permission and not fullscreen
        if hasAccessibilityPermission && !space.isFullScreen && space.index >= 1
            && space.index <= 20
        {
            print("NativeAdapter: Using keyboard simulation for space \(space.index)")
            simulateSpaceSwitch(to: space.index)
            return
        }

        // Method 2: Use AppleScript as fallback for fullscreen spaces or spaces > 20
        // Use if we have Apple Events permission
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

    /// Simulate keyboard shortcut to switch spaces using configured shortcuts
    private func simulateSpaceSwitch(to index: Int) {
        // Get the shortcut from settings
        guard let shortcut = AppSettings.shared.spaceSwitchShortcuts.shortcut(forSpace: index)
        else {
            print("NativeAdapter: No shortcut configured for space \(index)")
            return
        }

        let keyCode = shortcut.keyCode
        let flags = shortcut.cgEventFlags

        print(
            "NativeAdapter: Simulating \(shortcut.displayString) for space \(index) (keyCode: \(keyCode))"
        )

        let source = CGEventSource(stateID: .hidSystemState)

        // Create key down event with configured modifiers
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
            print("NativeAdapter: Posted key down event")
        } else {
            print("NativeAdapter: Failed to create key down event")
        }

        // Small delay between key down and key up
        usleep(50000)

        // Create key up event
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
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

        // Get the shortcut from settings for building AppleScript
        let shortcut = AppSettings.shared.spaceSwitchShortcuts.shortcut(forSpace: spaceIndex)

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
        } else if let shortcut = shortcut, spaceIndex >= 1 && spaceIndex <= 20 {
            // Use the configured shortcut
            let keyCode = shortcut.key
            var modifierParts: [String] = []
            if shortcut.modifiers.contains("control") { modifierParts.append("control down") }
            if shortcut.modifiers.contains("option") { modifierParts.append("option down") }
            if shortcut.modifiers.contains("shift") { modifierParts.append("shift down") }
            if shortcut.modifiers.contains("cmd") { modifierParts.append("command down") }

            let modifierString =
                modifierParts.isEmpty ? "" : " using {\(modifierParts.joined(separator: ", "))}"

            script = """
                tell application "System Events"
                    key code \(keyCode)\(modifierString)
                end tell
                """
        } else {
            // For spaces beyond 20, use Mission Control navigation
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

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("NativeAdapter: AppleScript error: \(error)")
            }
        }
    }
}
