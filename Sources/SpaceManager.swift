import Foundation
import Combine

/// Central manager for space operations, handles adapter selection
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()
    
    @Published var spaces: [Space] = []
    @Published var isYabaiMode: Bool = false
    
    private var adapter: SpaceService
    private let persistenceManager = PersistenceManager()
    
    init() {
        // Check user preference
        let defaults = UserDefaults.standard
        let preferredMode = defaults.string(forKey: "preferredMode")
        
        // If explicitly set to native, use native
        if preferredMode == "native" {
            self.adapter = NativeAdapter(persistenceManager: persistenceManager)
            self.isYabaiMode = false
            print("Using Native mode (User preference)")
            refreshSpaces()
            return
        }
        
        // Otherwise try Yabai (default behavior)
        let yabai = YabaiAdapter()
        if yabai.isAvailable {
            self.adapter = yabai
            self.isYabaiMode = true
            print("Using Yabai mode")
        } else {
            self.adapter = NativeAdapter(persistenceManager: persistenceManager)
            self.isYabaiMode = false
            print("Using Native mode (Yabai not available)")
        }
        
        refreshSpaces()
    }
    
    func setMode(isYabai: Bool) {
        if isYabai {
            let yabai = YabaiAdapter()
            if yabai.isAvailable {
                self.adapter = yabai
                self.isYabaiMode = true
            } else {
                // Failed to switch
                print("Cannot switch to Yabai: not available")
                return
            }
        } else {
            self.adapter = NativeAdapter(persistenceManager: persistenceManager)
            self.isYabaiMode = false
        }
        
        // Save preference
        UserDefaults.standard.set(isYabai ? "yabai" : "native", forKey: "preferredMode")
        refreshSpaces()
    }
    
    func refreshSpaces() {
        spaces = adapter.getSpaces()
    }
    
    func switchTo(space: Space) {
        adapter.switchTo(space: space)
    }
    
    func renameSpace(space: Space, to name: String) {
        adapter.renameSpace(space: space, to: name)
        
        // Refresh to show updated name - give yabai a moment to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshSpaces()
        }
    }
    
    func renameCurrentSpace(to name: String) {
        guard let current = adapter.getCurrentSpace() else { 
            print("SpaceManager: No current space found")
            return 
        }
        renameSpace(space: current, to: name)
    }
}
