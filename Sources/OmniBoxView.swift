import Combine
import SwiftUI

struct OmniBoxView: View {
    @ObservedObject var spaceManager: SpaceManager
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isTextFieldFocused: Bool
    @State private var eventMonitor: Any?

    // Current space for display
    private var currentSpace: Space? {
        spaceManager.spaces.first(where: { $0.isCurrent })
    }

    private func getFilteredSpaces() -> [Space] {
        if searchText.isEmpty {
            return spaceManager.spaces
        }
        let query = searchText.lowercased()
        return spaceManager.spaces.filter { space in
            fuzzyMatch(query: query, target: space.displayName.lowercased())
        }
    }

    var body: some View {
        mainContent
            .frame(width: 560, height: 380)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(borderOverlay)
            .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 15)
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
            .onChange(of: searchText) {
                // Reset selection when search changes
                selectedIndex = 0
            }
    }

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            Color(nsColor: NSColor.windowBackgroundColor).opacity(0.7)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
                .background(Color.white.opacity(0.1))
            resultsList
            helpBar
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        let filtered = getFilteredSpaces()
        let renameMode = !searchText.isEmpty && filtered.isEmpty

        VStack(spacing: 8) {
            // Current space indicator
            if let current = currentSpace {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Current: \(current.displayName)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            HStack(spacing: 14) {
                Image(systemName: renameMode ? "pencil" : "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(renameMode ? Color.accentColor : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: renameMode)

                TextField("Search spaces or type to rename...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .focused($isTextFieldFocused)
                // Don't use onSubmit - let the key event monitor handle all Enter presses

                if !searchText.isEmpty {
                    clearButton
                }

                modeIndicator

                settingsButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    @ViewBuilder
    private var clearButton: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.15)) {
                searchText = ""
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.secondary.opacity(0.8))
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }

    @ViewBuilder
    private var modeIndicator: some View {
        let modeText = spaceManager.isYabaiMode ? "yabai" : "native"
        let modeColor = spaceManager.isYabaiMode ? Color.green : Color.orange

        HStack(spacing: 4) {
            Circle()
                .fill(modeColor)
                .frame(width: 6, height: 6)
            Text(modeText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(modeColor.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var settingsButton: some View {
        Button(action: {
            onOpenSettings()
        }) {
            Image(systemName: "gear")
                .font(.system(size: 14))
                .foregroundColor(Color.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .help("Settings")
    }

    @ViewBuilder
    private var resultsList: some View {
        let spacesToShow = getFilteredSpaces()
        let renameMode = !searchText.isEmpty && spacesToShow.isEmpty

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if renameMode {
                        RenamePromptRow(name: searchText)
                            .onTapGesture(perform: renameCurrentSpace)
                    } else {
                        ForEach(Array(spacesToShow.enumerated()), id: \.offset) {
                            index, space in
                            SpaceRow(
                                space: space,
                                isSelected: index == selectedIndex,
                                isCurrent: space.isCurrent
                            )
                            .id(index)
                            .onTapGesture {
                                selectedIndex = index
                                handleSubmit()
                            }
                        }
                    }

                    if spacesToShow.isEmpty && searchText.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
            }
            .onChange(of: selectedIndex) {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 40))
                .foregroundColor(Color.secondary.opacity(0.5))
            Text("No spaces found")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var helpBar: some View {
        HStack(spacing: 16) {
            HelpItem(key: "↵", action: "Switch")
            HelpItem(key: "⌘↵", action: "Rename")
            HelpItem(key: "↑↓", action: "Navigate")
            HelpItem(key: "esc", action: "Close")
            Spacer()
            Text("v\(AppInfo.version)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.secondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private func handleAppear() {
        isTextFieldFocused = true
        spaceManager.refreshSpaces()
        selectedIndex = 0
        searchText = ""

        // Setup key event monitor for navigation
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event)
        }
    }

    private func handleDisappear() {
        // Clean up event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 53:  // Escape
            onDismiss()
            return nil
        case 125:  // Down arrow
            moveSelection(by: 1)
            return nil
        case 126:  // Up arrow
            moveSelection(by: -1)
            return nil
        case 36:  // Return/Enter
            if event.modifierFlags.contains(.command) {
                // Cmd+Enter always renames (even if there are matches)
                performRename()
                return nil
            } else {
                // Regular Enter - switch if matches exist, rename if no matches
                handleSubmit()
                return nil
            }
        default:
            return event
        }
    }

    private func moveSelection(by offset: Int) {
        let filtered = getFilteredSpaces()
        let renameMode = !searchText.isEmpty && filtered.isEmpty
        guard !renameMode else { return }

        let newIndex = selectedIndex + offset
        if newIndex >= 0 && newIndex < filtered.count {
            selectedIndex = newIndex
        }
    }

    private func handleSubmit() {
        let filtered = getFilteredSpaces()
        let renameMode = !searchText.isEmpty && filtered.isEmpty

        // If in rename mode (no matching spaces), rename current space
        if renameMode {
            performRename()
            return
        }

        // If there are no filtered spaces, do nothing
        guard !filtered.isEmpty else { return }

        // If selected index is out of bounds, do nothing
        guard selectedIndex >= 0 && selectedIndex < filtered.count else { return }

        let targetSpace = filtered[selectedIndex]
        spaceManager.switchTo(space: targetSpace)
        onDismiss()
    }

    private func performRename() {
        let nameToSave = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nameToSave.isEmpty else { return }

        // Get the current space - try isCurrent first, then fall back to first space
        let currentSpace =
            spaceManager.spaces.first(where: { $0.isCurrent }) ?? spaceManager.spaces.first
        guard let space = currentSpace else { return }

        // Perform rename first
        spaceManager.renameSpace(space: space, to: nameToSave)

        // Then clear text
        searchText = ""
        selectedIndex = 0
    }

    // Keep old function for compatibility but redirect to performRename
    private func renameCurrentSpace() {
        performRename()
    }

    private func fuzzyMatch(query: String, target: String) -> Bool {
        // Simple contains match for better UX
        if target.contains(query) {
            return true
        }

        // Fuzzy character sequence match
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                queryIndex = query.index(after: queryIndex)
            }
            targetIndex = target.index(after: targetIndex)
        }

        return queryIndex == query.endIndex
    }
}

struct SpaceRow: View {
    let space: Space
    let isSelected: Bool
    let isCurrent: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            spaceIcon
            spaceInfo
            Spacer()
            if isCurrent {
                currentBadge
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(selectionBorder)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            Color.accentColor.opacity(0.25)
        } else if isHovered {
            Color.primary.opacity(0.05)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1.5)
        }
    }

    @ViewBuilder
    private var spaceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isCurrent
                        ? LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .top, endPoint: .bottom)
                        : LinearGradient(
                            colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.15)],
                            startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 40, height: 40)

            Text("\(space.index)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isCurrent ? Color.white : Color.primary.opacity(0.8))
        }
    }

    @ViewBuilder
    private var spaceInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(space.displayName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color.primary)

            if let label = space.label, !label.isEmpty, label != space.displayName {
                Text("Desktop \(space.index)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
            }
        }
    }

    @ViewBuilder
    private var currentBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text("Active")
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.green.opacity(0.15))
        .clipShape(Capsule())
    }

}

struct RenamePromptRow: View {
    let name: String

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Rename current space to")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
                Text("\"\(name)\"")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.primary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "return")
                    .font(.system(size: 10))
                Text("Enter")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Color.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(isHovered ? 0.15 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct HelpItem: View {
    let key: String
    let action: String

    var body: some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(Color.primary.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(action)
                .font(.system(size: 10))
                .foregroundColor(Color.secondary)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
