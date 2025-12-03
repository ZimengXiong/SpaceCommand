import AppKit
import Combine
import Foundation

/// Central manager for space operations
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()

    @Published var spaces: [Space] = []
    @Published var isYabaiAvailable: Bool = false
    @Published var isNativeAvailable: Bool = false
    @Published var currentMode: SpaceMode = .auto
    @Published var activeAdapterName: String = "None"

    private let yabaiAdapter: YabaiAdapter
    private let nativeAdapter: NativeAdapter
    private let logger = Logger.shared
    private var activeAdapter: SpaceService?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.yabaiAdapter = YabaiAdapter()
        self.nativeAdapter = NativeAdapter()

        self.currentMode = AppSettings.shared.spaceMode

        self.isYabaiAvailable = yabaiAdapter.isAvailable
        self.isNativeAvailable = nativeAdapter.isAvailable

        // Sync labels from Yabai if available (this populates AppSettings with Yabai labels if missing)
        if isYabaiAvailable {
            _ = yabaiAdapter.getSpaces()
        }

        updateActiveAdapter()

        AppSettings.shared.$spaceMode
            .sink { [weak self] newMode in
                self?.currentMode = newMode
                self?.updateActiveAdapter()
                self?.refreshSpaces()
            }
            .store(in: &cancellables)

        logger.info(
            "SpaceCommand initialized - Yabai: \(isYabaiAvailable ? "Yes" : "No"), Native: \(isNativeAvailable ? "Yes" : "No")"
        )
        refreshSpaces()
    }

    private func updateActiveAdapter() {
        switch currentMode {
        case .auto:
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

        logger.info("SpaceCommand: Active adapter is now \(activeAdapterName)")
    }

    func refreshSpaces() {
        isYabaiAvailable = yabaiAdapter.isAvailable
        isNativeAvailable = nativeAdapter.isAvailable

        updateActiveAdapter()

        spaces = activeAdapter?.getSpaces() ?? []
    }

    func switchTo(space: Space) {
        logger.debug("SpaceManager.switchTo called for space \(space.index) (id: \(space.id))")
        logger.debug("SpaceManager: Using adapter \(activeAdapterName)")

        if let nativeAdapter = activeAdapter as? NativeAdapter {
            nativeAdapter.checkPermissions()

            if !nativeAdapter.hasAccessibilityPermissionPublic
                && !nativeAdapter.hasAppleEventsPermissionPublic
            {
                logger.info("SpaceManager: No native permissions, requesting...")
                DispatchQueue.main.async {
                    nativeAdapter.requestAccessibilityPermission()
                }
                return
            }
        }

        activeAdapter?.switchTo(space: space)
        logger.debug("SpaceManager: switchTo completed")
    }

    func renameSpace(space: Space, to name: String) {
        activeAdapter?.renameSpace(space: space, to: name)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshSpaces()
        }
    }

    func renameCurrentSpace(to name: String) {
        guard let current = activeAdapter?.getCurrentSpace() else {
            logger.warning("SpaceManager: No current space found")
            return
        }
        renameSpace(space: current, to: name)
    }

    func switchToSpace(by index: Int) {
        logger.debug("SpaceManager.switchToSpace called for index \(index)")

        refreshSpaces()

        guard let space = spaces.first(where: { $0.index == index }) else {
            logger.warning("SpaceManager: No space found with index \(index)")
            return
        }

        switchTo(space: space)
    }

    var hasAvailableBackend: Bool {
        return isYabaiAvailable || isNativeAvailable
    }

    func ensurePermissions() {

        if currentMode == .native || (currentMode == .auto && !isYabaiAvailable) {
            nativeAdapter.ensurePermissionsOnFirstLaunch()
        }
    }
}
