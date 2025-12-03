import AppKit  // Import AppKit for NSEvent.ModifierFlags
import Carbon
import Foundation

// Make EventHotKeyID Hashable and Equatable
extension EventHotKeyID: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(signature)
        hasher.combine(id)
    }

    public static func == (lhs: EventHotKeyID, rhs: EventHotKeyID) -> Bool {
        return lhs.signature == rhs.signature && lhs.id == rhs.id
    }
}

/// Manages global hotkey registration using Carbon Event Manager
class HotkeyManager {
    private var hotkeyRefs: [EventHotKeyID: EventHotKeyRef] = [:]
    private var hotkeyHandlers: [EventHotKeyID: () -> Void] = [:]
    private var nextHotKeyID: UInt32 = 1

    /// Convert NSEvent.ModifierFlags to Carbon modifier flags
    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
        if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
        return carbonFlags
    }

    init() {
        // Install event handler for all hotkeys managed by this manager
        let refcon = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        var eventHandler: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)

                if let handler = manager.hotkeyHandlers[hotkeyID] {
                    DispatchQueue.main.async {
                        handler()
                    }
                }

                return noErr
            },
            1,
            &eventType,
            refcon,
            &eventHandler
        )

        if status != noErr {
            print("Failed to install event handler: \(status)")
        }
    }

    deinit {
        unregisterAll()
    }

    /// Register a custom hotkey
    func register(key: UInt32, modifierFlags: NSEvent.ModifierFlags, handler: @escaping () -> Void)
    {
        let hotkeyID = EventHotKeyID(signature: OSType(0x5343_4D44), id: nextHotKeyID)
        nextHotKeyID += 1

        let carbonMods = carbonModifiers(from: modifierFlags)

        var hotkeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            key,
            carbonMods,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if registerStatus != noErr {
            print(
                "Failed to register hotkey (Key: \(key), Carbon Modifiers: \(carbonMods)): \(registerStatus)"
            )
        } else if let ref = hotkeyRef {
            hotkeyRefs[hotkeyID] = ref
            hotkeyHandlers[hotkeyID] = handler
            print("Global hotkey registered: Key \(key), Carbon Modifiers \(carbonMods)")
        }
    }

    /// Register the default Cmd+Shift+Space hotkey
    func registerDefaultHotkey(handler: @escaping () -> Void) {
        register(key: UInt32(kVK_Space), modifierFlags: [.command, .shift], handler: handler)
    }

    /// Unregister all hotkeys
    func unregisterAll() {
        for (_, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
        hotkeyHandlers.removeAll()
    }
}
