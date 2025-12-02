import Carbon
import Foundation

/// Manages global hotkey registration using Carbon Event Manager
class HotkeyManager {
    private var hotkeyRef: EventHotKeyRef?
    private let action: () -> Void
    
    // Unique ID for this hotkey
    private let hotkeyID = EventHotKeyID(signature: OSType(0x5343_4D44), id: 1)  // "SCMD"
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    deinit {
        unregister()
    }
    
    /// Register Cmd+Shift+Space hotkey
    func register() {
        // Store reference to self for the callback
        let refcon = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        
        // Define event type spec
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Install event handler
        var eventHandler: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                
                // Verify it's our hotkey
                var hotkeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                  nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
                
                if hotkeyID.signature == manager.hotkeyID.signature && hotkeyID.id == manager.hotkeyID.id {
                    DispatchQueue.main.async {
                        manager.action()
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
            return
        }
        
        // Register the hotkey: Cmd+Shift+Space
        // Key codes: Space = 0x31
        // Modifiers: cmdKey = 0x0100, shiftKey = 0x0200
        var hotkeyID = self.hotkeyID
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | shiftKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if registerStatus != noErr {
            print("Failed to register hotkey: \(registerStatus)")
        } else {
            print("Global hotkey registered: Cmd+Shift+Space")
        }
    }
    
    /// Unregister the hotkey
    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
    }
}
