import Cocoa
import Foundation
import Security
import ServiceManagement

class NativeAdapter: SpaceService, @unchecked Sendable {
    private let conn = _CGSDefaultConnection()
    private let defaults = UserDefaults.standard
    private let permissionsCheckedKey = "permissionsInitiallyChecked"
    private var hasAccessibilityPermission: Bool = false
    private var hasAppleEventsPermission: Bool = false
    private let logger = Logger.shared

    func checkPermissions() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasAppleEventsPermission = checkAppleEventsPermission()
    }

    func ensurePermissionsOnFirstLaunch() {
        checkPermissions()

        if !hasAppleEventsPermission {
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
            _ = appleScript.executeAndReturnError(&error)
            if error == nil {
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

    func switchTo(space: Space) async {
        checkPermissions()

        if !hasAccessibilityPermission && !hasAppleEventsPermission {
            requestAccessibilityPermission()
            return
        }

        if hasAccessibilityPermission && !space.isFullScreen && space.index >= 1
            && space.index <= 10
        {
            for _ in 1...3 {
                let success = await simulateSpaceSwitchWithCGEvent(to: space.index)
                if success {
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    if getCurrentSpace()?.index == space.index {
                        return
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        if hasAppleEventsPermission {
            for _ in 1...2 {
                switchViaAppleScript(spaceIndex: space.index, isFullScreen: space.isFullScreen)
                try? await Task.sleep(nanoseconds: 200_000_000)
                if getCurrentSpace()?.index == space.index {
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        if !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }

    func renameSpace(space: Space, to name: String) {
        AppSettings.shared.setLabel(for: space.id, label: name)
    }

    private func simulateSpaceSwitchWithCGEvent(to index: Int) async -> Bool {
        let keyCodes: [Int: CGKeyCode] = [
            1: 18, 2: 19, 3: 20, 4: 21, 5: 23,
            6: 22, 7: 26, 8: 28, 9: 25, 10: 29,
        ]

        guard let keyCode = keyCodes[index] else { return false }

        let sourceStates: [CGEventSourceStateID] = [.hidSystemState, .combinedSessionState]

        for sourceState in sourceStates {
            guard let source = CGEventSource(stateID: sourceState) else { continue }
            guard
                let keyDown = CGEvent(
                    keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
            else { continue }
            keyDown.flags = .maskControl
            guard
                let keyUp = CGEvent(
                    keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            else { continue }
            keyUp.flags = .maskControl

            keyDown.post(tap: .cghidEventTap)
            try? await Task.sleep(nanoseconds: 30_000_000)
            keyUp.post(tap: .cghidEventTap)
            return true
        }
        return false
    }

    private func switchViaAppleScript(spaceIndex: Int, isFullScreen: Bool) {
        let numberKeyCodes: [Int: Int] = [
            1: 18, 2: 19, 3: 20, 4: 21, 5: 23,
            6: 22, 7: 26, 8: 28, 9: 25, 10: 29,
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

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
}
