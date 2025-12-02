import Foundation
import Combine

/// Central manager for space operations, handles adapter selection
class SpaceManager: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var isYabaiMode: Bool = false
    
    private var adapter: SpaceService
    private let persistenceManager = PersistenceManager()
    
    init() {
        // Try Yabai first, fall back to Native
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
    
    func refreshSpaces() {
        spaces = adapter.getSpaces()
    }
    
    func switchTo(space: Space) {
        adapter.switchTo(space: space)
    }
    
    func renameCurrentSpace(to name: String) {
        guard let current = adapter.getCurrentSpace() else { return }
        adapter.renameSpace(space: current, to: name)
        refreshSpaces()
    }
}
