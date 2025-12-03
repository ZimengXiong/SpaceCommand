import SwiftUI

struct ShortcutRecorderButton: View {
    @Binding var shortcut: KeyboardShortcut
    @Binding var isRecording: Bool

    var body: some View {
        Button(action: { isRecording.toggle() }) {
            HStack(spacing: 4) {
                if isRecording {
                    Text("Type shortcut...")
                        .foregroundColor(.secondary)
                } else {
                    Text(shortcut.displayString)
                        .fontWeight(.medium)
                }
            }
            .font(.system(size: 12, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isRecording ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .background(
            ShortcutRecorderView(isRecording: $isRecording, shortcut: $shortcut)
        )
    }
}

// MARK: - NSView wrapper for keyboard event capture
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcut: KeyboardShortcut

    func makeNSView(context: Context) -> ShortcutCaptureView {
        let view = ShortcutCaptureView()
        view.onShortcutCaptured = { key, modifiers in
            shortcut = KeyboardShortcut(key: key, modifiers: modifiers)
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureView, context: Context) {
        if isRecording && !nsView.isRecording {
            nsView.startRecording()
        } else if !isRecording && nsView.isRecording {
            nsView.stopRecording()
        }
    }
}

class ShortcutCaptureView: NSView {
    var isRecording = false
    var onShortcutCaptured: ((UInt32, [String]) -> Void)?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var flagsMonitor: Any?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    func startRecording() {
        isRecording = true

        let handleKeyEvent: (NSEvent) -> Bool = { [weak self] event in
            guard let self = self, self.isRecording else { return false }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
                return true
            }

            let acceptableModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
            guard !modifiers.intersection(acceptableModifiers).isEmpty else {
                return false
            }

            var modifierStrings: [String] = []
            if modifiers.contains(.command) { modifierStrings.append("cmd") }
            if modifiers.contains(.shift) { modifierStrings.append("shift") }
            if modifiers.contains(.option) { modifierStrings.append("option") }
            if modifiers.contains(.control) { modifierStrings.append("control") }

            DispatchQueue.main.async {
                self.onShortcutCaptured?(UInt32(event.keyCode), modifierStrings)
                self.stopRecording()
            }
            return true
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if handleKeyEvent(event) {
                return nil
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handleKeyEvent(event)
        }

        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            return event
        }
    }

    func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }

    deinit {
        stopRecording()
    }
}
