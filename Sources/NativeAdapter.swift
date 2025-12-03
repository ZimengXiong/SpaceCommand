import Cocoa
import Foundation
import Security
import ServiceManagement

class NativeAdapter: SpaceService {
    private let conn = _CGSDefaultConnection()
    private let defaults = UserDefaults.standard
    private let permissionsCheckedKey = "permissionsInitiallyChecked"
    private var hasAccessibilityPermission: Bool = false
    private var hasAppleEventsPermission: Bool = false
    private let logger = Logger.shared

    func checkPermissions() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasAppleEventsPermission = checkAppleEventsPermission()
        logger.debug(
            "NativeAdapter: Permissions check - Accessibility: \(hasAccessibilityPermission), Automation: \(hasAppleEventsPermission)"
        )
    }

    func ensurePermissionsOnFirstLaunch() {
        checkPermissions()

        logger.debug(
            "NativeAdapter: ensurePermissionsOnFirstLaunch - Accessibility: \(hasAccessibilityPermission), Automation: \(hasAppleEventsPermission)"
        )

        if !hasAppleEventsPermission {
            logger.info("NativeAdapter: Triggering System Events permission prompt...")
            triggerSystemEventsPermissionPrompt()
        }

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
                let options: NSDictionary = [
                    kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
                ]
                AXIsProcessTrustedWithOptions(options)
            }
        }

        checkPermissions()
    }

    private func triggerSystemEventsPermissionPrompt() {

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
                logger.debug(
                    "NativeAdapter: AppleScript error (expected if permission not yet granted): \(error)"
                )

            } else {
                let outputString = result.stringValue ?? "nil"
                logger.debug(
                    "NativeAdapter: AppleScript executed successfully, result: \(outputString)")
                hasAppleEventsPermission = true
            }
        }
    }

    public var hasAccessibilityPermissionPublic: Bool {
        return hasAccessibilityPermission
    }

    public var hasAppleEventsPermissionPublic: Bool {
        return hasAppleEventsPermission
    }

    private func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        return accessibilityEnabled
    }

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

            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options)

            if let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            {
                NSWorkspace.shared.open(url)
            }
        }
    }

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

            if let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
            ) {
                NSWorkspace.shared.open(url)
            }
        } else if response == .alertSecondButtonReturn {

            let script = """
                tell application "System Events"
                    return name of first process
                end tell
                """

            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if error != nil {

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

                    checkPermissions()
                }
            }
        }
    }

    var isAvailable: Bool {

        checkPermissions()

        let spaces = getSpaces()
        let basicAvailability = !spaces.isEmpty

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

                if !isFullScreen {
                    desktopNumber += 1
                }

                spaceIndex += 1

                var label: String? = AppSettings.shared.getLabel(for: spaceIDString)

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
        logger.debug(
            "NativeAdapter.switchTo called for space \(space.index) (id: \(space.id), fullscreen: \(space.isFullScreen))"
        )

        checkPermissions()
        logger.debug(
            "NativeAdapter: accessibility=\(hasAccessibilityPermission), appleEvents=\(hasAppleEventsPermission)"
        )

        if let bundleID = Bundle.main.bundleIdentifier {
            logger.debug("NativeAdapter: Running as bundle: \(bundleID)")
        }
        logger.debug("NativeAdapter: Executable path: \(Bundle.main.executablePath ?? "unknown")")

        if !hasAccessibilityPermission && !hasAppleEventsPermission {
            logger.info("NativeAdapter: No permissions, requesting...")
            requestAccessibilityPermission()
            return
        }

        let currentSpaceBefore = getCurrentSpace()
        logger.debug(
            "NativeAdapter: Current space before switch: \(currentSpaceBefore?.index ?? -1)")

        if hasAccessibilityPermission && !space.isFullScreen && space.index >= 1
            && space.index <= 10
        {
            logger.debug(
                "NativeAdapter: Using CGEvent keyboard simulation for space \(space.index)")

            for attempt in 1...3 {
                logger.debug("NativeAdapter: CGEvent attempt \(attempt)")
                let success = simulateSpaceSwitchWithCGEvent(to: space.index)
                if success {
                    usleep(150000)
                    let currentSpaceAfter = getCurrentSpace()
                    logger.debug(
                        "NativeAdapter: Current space after CGEvent: \(currentSpaceAfter?.index ?? -1)"
                    )

                    if currentSpaceAfter?.index == space.index {
                        logger.info("NativeAdapter: CGEvent switch verified successful!")
                        return
                    }
                    logger.debug(
                        "NativeAdapter: CGEvent posted but switch not verified, attempt \(attempt)")
                }
                usleep(100000)
            }
            logger.info(
                "NativeAdapter: CGEvent failed after 3 attempts, trying AppleScript fallback")
        }

        if hasAppleEventsPermission {
            for attempt in 1...2 {
                logger.debug(
                    "NativeAdapter: AppleScript attempt \(attempt) for space \(space.index)")
                switchViaAppleScript(spaceIndex: space.index, isFullScreen: space.isFullScreen)

                usleep(200000)

                let currentSpaceAfter = getCurrentSpace()
                logger.debug(
                    "NativeAdapter: Current space after AppleScript: \(currentSpaceAfter?.index ?? -1)"
                )

                if currentSpaceAfter?.index == space.index {
                    logger.info("NativeAdapter: AppleScript switch verified successful!")
                    return
                }
                usleep(100000)
            }
        }

        logger.warning("NativeAdapter: All switching methods failed")
        if !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }

    func renameSpace(space: Space, to name: String) {
        AppSettings.shared.setLabel(for: space.id, label: name)
    }

    private func simulateSpaceSwitchWithCGEvent(to index: Int) -> Bool {
        let keyCodes: [Int: CGKeyCode] = [
            1: 18,
            2: 19,
            3: 20,
            4: 21,
            5: 23,
            6: 22,
            7: 26,
            8: 28,
            9: 25,
            10: 29,
        ]

        guard let keyCode = keyCodes[index] else {
            logger.warning("NativeAdapter: Invalid space index \(index), cannot simulate key press")
            return false
        }

        logger.debug(
            "NativeAdapter: Simulating Ctrl+\(index == 10 ? "0" : String(index)) (keyCode: \(keyCode))"
        )

        let sourceStates: [CGEventSourceStateID] = [.hidSystemState, .combinedSessionState]

        for sourceState in sourceStates {
            logger.debug("NativeAdapter: Trying CGEventSource state: \(sourceState.rawValue)")

            guard let source = CGEventSource(stateID: sourceState) else {
                logger.warning(
                    "NativeAdapter: Failed to create event source with state \(sourceState.rawValue)"
                )
                continue
            }

            guard
                let keyDown = CGEvent(
                    keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
            else {
                logger.warning("NativeAdapter: Failed to create key down event")
                continue
            }

            keyDown.flags = .maskControl
            guard
                let keyUp = CGEvent(
                    keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            else {
                logger.warning("NativeAdapter: Failed to create key up event")
                continue
            }

            keyUp.flags = .maskControl
            logger.debug("NativeAdapter: Posting to cghidEventTap")
            keyDown.post(tap: .cghidEventTap)
            usleep(30000)
            keyUp.post(tap: .cghidEventTap)

            logger.debug(
                "NativeAdapter: Posted key events with sourceState \(sourceState.rawValue) to cghidEventTap"
            )
            return true
        }

        logger.warning("NativeAdapter: All CGEvent approaches failed")
        return false
    }

    private func switchViaAppleScript(spaceIndex: Int, isFullScreen: Bool) {
        let numberKeyCodes: [Int: Int] = [
            1: 18,
            2: 19,
            3: 20,
            4: 21,
            5: 23,
            6: 22,
            7: 26,
            8: 28,
            9: 25,
            10: 29,
        ]

        let script: String
        if isFullScreen {

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

            if spaceIndex >= 1 && spaceIndex <= 10, let keyCode = numberKeyCodes[spaceIndex] {
                logger.debug(
                    "NativeAdapter: AppleScript using key code \(keyCode) for space \(spaceIndex)")
                script = """
                    tell application "System Events"
                        key code \(keyCode) using control down
                    end tell
                    """
            } else {

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

        logger.debug("NativeAdapter: Executing AppleScript: \(script)")
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let error = error {
                logger.error("NativeAdapter: AppleScript error: \(error)")
            } else {
                logger.debug("NativeAdapter: AppleScript executed successfully, result: \(result)")
            }
        } else {
            logger.warning("NativeAdapter: Failed to create AppleScript")
        }
    }
}
