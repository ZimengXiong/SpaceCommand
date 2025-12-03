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

    // Sort spaces with current space first
    private func getSortedSpaces() -> [Space] {
        var spaces = spaceManager.spaces
        // Move current space to top
        if let currentIndex = spaces.firstIndex(where: { $0.isCurrent }) {
            let current = spaces.remove(at: currentIndex)
            spaces.insert(current, at: 0)
        }
        return spaces
    }

    private func getFilteredSpaces() -> [Space] {
        let sorted = getSortedSpaces()
        if searchText.isEmpty {
            return sorted
        }
        let query = searchText.lowercased()
        let matches = sorted.filter { space in
            fuzzyMatch(query: query, target: space.displayName.lowercased())
        }

        // Sort: custom-named spaces first, then by match quality
        return matches.sorted { a, b in
            let aHasCustomName = a.label != nil && !a.label!.isEmpty
            let bHasCustomName = b.label != nil && !b.label!.isEmpty

            // Custom-named spaces come first
            if aHasCustomName && !bHasCustomName { return true }
            if !aHasCustomName && bHasCustomName { return false }

            // Among same type, prefer exact prefix matches
            let aName = a.displayName.lowercased()
            let bName = b.displayName.lowercased()
            let aStartsWith = aName.hasPrefix(query)
            let bStartsWith = bName.hasPrefix(query)

            if aStartsWith && !bStartsWith { return true }
            if !aStartsWith && bStartsWith { return false }

            // Keep current space at top within same category
            if a.isCurrent && !b.isCurrent { return true }
            if !a.isCurrent && b.isCurrent { return false }

            return a.index < b.index
        }
    }

    var body: some View {
        mainContent
            .frame(width: 520, height: 360)
            .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
            .onChange(of: searchText) {
                selectedIndex = 0
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
                .background(Color.primary.opacity(0.1))
            resultsList
            helpBar
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        let filtered = getFilteredSpaces()
        let renameMode = !searchText.isEmpty && filtered.isEmpty

        HStack(spacing: 12) {
            Image(systemName: renameMode ? "pencil" : "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(renameMode ? Color.accentColor : Color.secondary)
                .animation(.easeInOut(duration: 0.2), value: renameMode)

            TextField("Search or type to rename...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 20, weight: .regular))
                .focused($isTextFieldFocused)

            if !searchText.isEmpty {
                clearButton
            }

            modeIndicator

            settingsButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.6))
    }

    @ViewBuilder
    private var clearButton: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.15)) {
                searchText = ""
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color.secondary.opacity(0.7))
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }

    @ViewBuilder
    private var modeIndicator: some View {
        let modeText = spaceManager.isYabaiAvailable ? "yabai" : "offline"
        let modeColor = spaceManager.isYabaiAvailable ? Color.green : Color.red

        HStack(spacing: 4) {
            Circle()
                .fill(modeColor)
                .frame(width: 5, height: 5)
            Text(modeText)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(modeColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var settingsButton: some View {
        Button(action: {
            onOpenSettings()
        }) {
            Image(systemName: "gear")
                .font(.system(size: 13))
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
                LazyVStack(spacing: 2) {
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
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
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
        VStack(spacing: 10) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 32))
                .foregroundColor(Color.secondary.opacity(0.4))
            Text("No spaces found")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    @ViewBuilder
    private var helpBar: some View {
        HStack(spacing: 14) {
            HelpItem(key: "↵", action: "Switch")
            HelpItem(key: "⌘↵", action: "Rename")
            HelpItem(key: "↑↓", action: "Navigate")
            HelpItem(key: "esc", action: "Close")
            Spacer()
            Text("v\(AppInfo.version)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.4))
    }

    private func handleAppear() {
        isTextFieldFocused = true
        spaceManager.refreshSpaces()
        selectedIndex = 0
        searchText = ""

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event)
        }
    }

    private func handleDisappear() {
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
                performRename()
                return nil
            } else {
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

        if renameMode {
            performRename()
            return
        }

        guard !filtered.isEmpty else { return }
        guard selectedIndex >= 0 && selectedIndex < filtered.count else { return }

        let targetSpace = filtered[selectedIndex]
        spaceManager.switchTo(space: targetSpace)
        onDismiss()
    }

    private func performRename() {
        let nameToSave = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nameToSave.isEmpty else { return }

        let currentSpace =
            spaceManager.spaces.first(where: { $0.isCurrent }) ?? spaceManager.spaces.first
        guard let space = currentSpace else { return }

        spaceManager.renameSpace(space: space, to: nameToSave)
        searchText = ""
        selectedIndex = 0
    }

    private func renameCurrentSpace() {
        performRename()
    }

    private func fuzzyMatch(query: String, target: String) -> Bool {
        if target.contains(query) {
            return true
        }

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
        HStack(spacing: 12) {
            spaceIcon
            spaceInfo
            Spacer()
            if isCurrent {
                currentBadge
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(selectionBorder)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            Color.accentColor.opacity(0.2)
        } else if isHovered {
            Color.primary.opacity(0.04)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var spaceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    isCurrent
                        ? Color.accentColor
                        : Color.secondary.opacity(0.15)
                )
                .frame(width: 32, height: 32)

            Text("\(space.index)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(isCurrent ? Color.white : Color.primary.opacity(0.7))
        }
    }

    @ViewBuilder
    private var spaceInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(space.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.primary)

            if let label = space.label, !label.isEmpty, label != space.displayName {
                Text("Desktop \(space.index)")
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary)
            }
        }
    }

    @ViewBuilder
    private var currentBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.green)
                .frame(width: 5, height: 5)
            Text("Active")
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

}

struct RenamePromptRow: View {
    let name: String

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)

                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Rename current space to")
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
                Text("\"\(name)\"")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primary)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "return")
                    .font(.system(size: 9))
                Text("Enter")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(isHovered ? 0.12 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

struct HelpItem: View {
    let key: String
    let action: String

    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.primary.opacity(0.6))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(action)
                .font(.system(size: 9))
                .foregroundColor(Color.secondary)
        }
    }
}
