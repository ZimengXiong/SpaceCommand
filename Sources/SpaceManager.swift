import AppKit
import Combine
import Foundation

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
        self.isYabaiAvailable = false
        self.isNativeAvailable = false

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        AppSettings.shared.$spaceMode
            .sink { [weak self] newMode in
                self?.currentMode = newMode
                Task {
                    await self?.updateActiveAdapter()
                    await self?.refreshSpaces()
                }
            }
            .store(in: &cancellables)

        Task {
            await self.initializeAdapters()
            await self.refreshSpaces()
        }
    }

    private func initializeAdapters() async {
        self.isYabaiAvailable = await yabaiAdapter.isAvailable
        self.isNativeAvailable = nativeAdapter.isAvailable

        if isYabaiAvailable {
            _ = await yabaiAdapter.getSpaces()
        }

        await updateActiveAdapter()
    }

    private func updateActiveAdapter() async {
        let yabaiAvailable = await yabaiAdapter.isAvailable
        let nativeAvailable = nativeAdapter.isAvailable

        switch currentMode {
        case .auto:
            if yabaiAvailable {
                activeAdapter = yabaiAdapter
                activeAdapterName = "Yabai"
            } else if nativeAvailable {
                activeAdapter = nativeAdapter
                activeAdapterName = "Native"
            } else {
                activeAdapter = nil
                activeAdapterName = "None"
            }
        case .yabai:
            if yabaiAvailable {
                activeAdapter = yabaiAdapter
                activeAdapterName = "Yabai"
            } else {
                activeAdapter = nil
                activeAdapterName = "None (Yabai unavailable)"
            }
        case .native:
            if nativeAvailable {
                activeAdapter = nativeAdapter
                activeAdapterName = "Native"
            } else {
                activeAdapter = nil
                activeAdapterName = "None (Native unavailable)"
            }
        }
    }

    func refreshSpaces() async {
        isYabaiAvailable = await yabaiAdapter.isAvailable
        isNativeAvailable = nativeAdapter.isAvailable

        await updateActiveAdapter()

        spaces = await activeAdapter?.getSpaces() ?? []
    }

    func switchTo(space: Space) async {
        if let nativeAdapter = activeAdapter as? NativeAdapter {
            nativeAdapter.checkPermissions()
            if !nativeAdapter.hasAccessibilityPermissionPublic
                && !nativeAdapter.hasAppleEventsPermissionPublic
            {
                DispatchQueue.main.async {
                    nativeAdapter.requestAccessibilityPermission()
                }
                return
            }
        }
        await activeAdapter?.switchTo(space: space)
    }

    @objc private func spaceDidChange() {
        Task { @MainActor in
            await self.refreshSpaces()
        }
    }

    func renameSpace(space: Space, to name: String) async {
        await activeAdapter?.renameSpace(space: space, to: name)
        await refreshSpaces()
    }

    func renameCurrentSpace(to name: String) async {
        guard let current = await activeAdapter?.getCurrentSpace() else { return }
        await renameSpace(space: current, to: name)
    }

    func switchToSpace(by index: Int) async {
        await refreshSpaces()
        guard let space = spaces.first(where: { $0.index == index }) else { return }
        await switchTo(space: space)
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
