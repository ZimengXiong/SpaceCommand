import SwiftUI
import Carbon

@main
struct SpaceCommandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingPanel: FloatingPanel?
    private var hotkeyManager: HotkeyManager?
    private var spaceManager: SpaceManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize space manager with appropriate adapter
        spaceManager = SpaceManager()
        
        // Create and configure floating panel
        floatingPanel = FloatingPanel(spaceManager: spaceManager)
        
        // Setup global hotkey (Cmd+Shift+Space)
        hotkeyManager = HotkeyManager { [weak self] in
            self?.togglePanel()
        }
        hotkeyManager?.register()
        
        print("SpaceCommand launched. Press Cmd+Shift+Space to activate.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregister()
    }
    
    private func togglePanel() {
        guard let panel = floatingPanel else { return }
        
        if panel.isVisible {
            panel.hidePanel()
        } else {
            panel.showPanel()
        }
    }
}
