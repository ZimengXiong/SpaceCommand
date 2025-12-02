import SwiftUI

struct OmniBoxView: View {
    @ObservedObject var spaceManager: SpaceManager
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isTextFieldFocused: Bool
    
    private var filteredSpaces: [Space] {
        if searchText.isEmpty {
            return spaceManager.spaces
        }
        return spaceManager.spaces.filter { space in
            fuzzyMatch(query: searchText.lowercased(), target: space.displayName.lowercased())
        }
    }
    
    var body: some View {
        mainContent
            .frame(width: 600, height: 400)
            .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(borderOverlay)
            .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            .onAppear(perform: handleAppear)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            resultsList
            helpBar
        }
    }
    
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(Color.secondary)
            
            TextField("Search or name a space...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 24, weight: .light))
                .focused($isTextFieldFocused)
                .onSubmit(handleSubmit)
            
            if !searchText.isEmpty {
                clearButton
            }
            
            modeIndicator
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.95))
    }
    
    @ViewBuilder
    private var clearButton: some View {
        Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color.secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var modeIndicator: some View {
        let modeText = spaceManager.isYabaiMode ? "yabai" : "native"
        let modeColor = spaceManager.isYabaiMode ? Color.green : Color.orange
        
        Text(modeText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modeColor.opacity(0.3))
            .cornerRadius(4)
    }
    
    @ViewBuilder
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredSpaces) { space in
                    let index = filteredSpaces.firstIndex(where: { $0.id == space.id }) ?? 0
                    SpaceRow(
                        space: space,
                        isSelected: index == selectedIndex,
                        isCurrent: space.isCurrent
                    )
                    .onTapGesture {
                        selectedIndex = index
                        handleSubmit()
                    }
                }
                
                if !searchText.isEmpty && filteredSpaces.isEmpty {
                    RenamePromptRow(name: searchText)
                        .onTapGesture(perform: renameCurrentSpace)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.9))
    }
    
    @ViewBuilder
    private var helpBar: some View {
        HStack {
            HelpItem(key: "↵", action: "Switch")
            HelpItem(key: "⌘↵", action: "Rename")
            HelpItem(key: "↑↓", action: "Navigate")
            HelpItem(key: "esc", action: "Close")
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.8))
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
    }
    
    private func handleAppear() {
        isTextFieldFocused = true
        spaceManager.refreshSpaces()
        selectedIndex = 0
        
        // Setup key event monitor for navigation
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return handleKeyEvent(event)
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 53: // Escape
            onDismiss()
            return nil
        case 125: // Down arrow
            moveSelection(by: 1)
            return nil
        case 126: // Up arrow
            moveSelection(by: -1)
            return nil
        case 36: // Return
            if event.modifierFlags.contains(.command) {
                renameCurrentSpace()
            } else {
                handleSubmit()
            }
            return nil
        default:
            return event
        }
    }
    
    private func moveSelection(by offset: Int) {
        let newIndex = selectedIndex + offset
        if newIndex >= 0 && newIndex < filteredSpaces.count {
            selectedIndex = newIndex
        }
    }
    
    private func handleSubmit() {
        if !filteredSpaces.isEmpty && selectedIndex < filteredSpaces.count {
            let targetSpace = filteredSpaces[selectedIndex]
            spaceManager.switchTo(space: targetSpace)
            onDismiss()
        } else if !searchText.isEmpty {
            renameCurrentSpace()
        }
    }
    
    private func renameCurrentSpace() {
        guard !searchText.isEmpty else { return }
        spaceManager.renameCurrentSpace(to: searchText)
        searchText = ""
        spaceManager.refreshSpaces()
    }
    
    private func fuzzyMatch(query: String, target: String) -> Bool {
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
    
    var body: some View {
        HStack {
            spaceIcon
            spaceInfo
            Spacer()
            if isCurrent {
                currentBadge
            }
            shortcutHint
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private var spaceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Color.accentColor : Color.secondary.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Text("\(space.index)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(isCurrent ? Color.white : Color.primary)
        }
    }
    
    @ViewBuilder
    private var spaceInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(space.displayName)
                .font(.system(size: 16, weight: .medium))
            
            if let label = space.label, !label.isEmpty, label != space.displayName {
                Text("Space \(space.index)")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var currentBadge: some View {
        Text("Current")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.2))
            .cornerRadius(4)
    }
    
    @ViewBuilder
    private var shortcutHint: some View {
        Text("⌃\(space.index)")
            .font(.caption)
            .foregroundColor(Color.secondary)
    }
}

struct RenamePromptRow: View {
    let name: String
    
    var body: some View {
        HStack {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.accentColor)
            
            VStack(alignment: .leading) {
                Text("Name current space \"\(name)\"")
                    .font(.system(size: 16, weight: .medium))
                Text("Press Enter or ⌘Enter to save")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
}

struct HelpItem: View {
    let key: String
    let action: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Text(action)
                .font(.system(size: 11))
                .foregroundColor(Color.secondary)
        }
        .padding(.trailing, 12)
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
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
