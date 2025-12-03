import Combine
import Foundation

/// Central manager for space operations — supports both Yabai and Native modes
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()

    @Published var spaces: [Space] = []
    @Published var isYabaiAvailable: Bool = false
    @Published var isNativeAvailable: Bool = false
    @Published var currentMode: SpaceMode = .auto
    @Published var activeAdapterName: String = "None"

    private let yabaiAdapter: YabaiAdapter
    private let nativeAdapter: NativeAdapter
    private var activeAdapter: SpaceService?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.yabaiAdapter = YabaiAdapter()
        self.nativeAdapter = NativeAdapter()

        // Load saved mode preference
        self.currentMode = AppSettings.shared.spaceMode

        // Check availability
        self.isYabaiAvailable = yabaiAdapter.isAvailable
        self.isNativeAvailable = nativeAdapter.isAvailable

        // Select appropriate adapter based on mode
        updateActiveAdapter()

        // Listen for mode changes from settings
        AppSettings.shared.$spaceMode
            .sink { [weak self] newMode in
                self?.currentMode = newMode
                self?.updateActiveAdapter()
                self?.refreshSpaces()
            }
            .store(in: &cancellables)

        print(
            "SpaceCommand initialized - Yabai: \(isYabaiAvailable ? "✓" : "✗"), Native: \(isNativeAvailable ? "✓" : "✗")"
        )
        refreshSpaces()
    }

    /// Update the active adapter based on current mode and availability
    private func updateActiveAdapter() {
        switch currentMode {
        case .auto:
            // Prefer Yabai if available, fallback to Native
            if yabaiAdapter.isAvailable {
                activeAdapter = yabaiAdapter
                activeAdapterName = "Yabai"
            } else if nativeAdapter.isAvailable {
                activeAdapter = nativeAdapter
                activeAdapterName = "Native"
            } else {
                activeAdapter = nil
                activeAdapterName = "None"
            }
        case .yabai:
            if yabaiAdapter.isAvailable {
                activeAdapter = yabaiAdapter
                activeAdapterName = "Yabai"
            } else {
                activeAdapter = nil
                activeAdapterName = "None (Yabai unavailable)"
            }
        case .native:
            if nativeAdapter.isAvailable {
                activeAdapter = nativeAdapter
                activeAdapterName = "Native"
            } else {
                activeAdapter = nil
                activeAdapterName = "None (Native unavailable)"
            }
        }

        print("SpaceCommand: Active adapter is now \(activeAdapterName)")
    }

    func refreshSpaces() {
        isYabaiAvailable = yabaiAdapter.isAvailable
        isNativeAvailable = nativeAdapter.isAvailable

        // Re-evaluate adapter in case availability changed
        updateActiveAdapter()

        spaces = activeAdapter?.getSpaces() ?? []
    }

    func switchTo(space: Space) {
        print("SpaceManager.switchTo called for space \(space.index) (id: \(space.id))")
        print("SpaceManager: Using adapter \(activeAdapterName)")

        // Handle permissions for native adapter
        if let nativeAdapter = activeAdapter as? NativeAdapter {
            nativeAdapter.checkPermissions()

            // If no permissions available, prompt user before switching
            if !nativeAdapter.hasAccessibilityPermissionPublic
                && !nativeAdapter.hasAppleEventsPermissionPublic
            {
                print("SpaceManager: No native permissions, requesting...")
                DispatchQueue.main.async {
                    nativeAdapter.requestAccessibilityPermission()
                }
                return
            }
        }

        activeAdapter?.switchTo(space: space)
        print("SpaceManager: switchTo completed")
    }

    func renameSpace(space: Space, to name: String) {
        activeAdapter?.renameSpace(space: space, to: name)

        // Refresh to show updated name - give adapter a moment to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshSpaces()
        }
    }

    func renameCurrentSpace(to name: String) {
        guard let current = activeAdapter?.getCurrentSpace() else {
            print("SpaceManager: No current space found")
            return
        }
        renameSpace(space: current, to: name)
    }

    /// Check if any backend is available
    var hasAvailableBackend: Bool {
        return isYabaiAvailable || isNativeAvailable
    }
}
