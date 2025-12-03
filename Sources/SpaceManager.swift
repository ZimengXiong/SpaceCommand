import Foundation
import Combine

/// Central manager for space operations — only Yabai is supported now
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()

    @Published var spaces: [Space] = []
    @Published var isYabaiAvailable: Bool = false

    private let adapter: YabaiAdapter

    init() {
        self.adapter = YabaiAdapter()
        self.isYabaiAvailable = adapter.isAvailable
        if isYabaiAvailable {
            print("SpaceCommand initialized with Yabai adapter")
        } else {
            print("SpaceCommand: yabai not available; please install yabai to use this app")
        }
        refreshSpaces()
    }

    func refreshSpaces() {
        isYabaiAvailable = adapter.isAvailable
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
