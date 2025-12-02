PROJECT MANIFEST: SpaceCommand

1. OBJECTIVE
   Build a macOS utility that allows users to name virtual desktops (Spaces) and switch to them via a fuzzy-find text interface.

Core Requirements:

UI: A Spotlight-like floating input bar (centered, borderless, floating).

Activation: Global hotkey (e.g., Cmd+Shift+Space) opens the renaming/switching input.

Modes:

Yabai Mode (Priority): Uses yabai CLI for state and navigation.

Native Mode (Fallback): Uses private CoreGraphics APIs (CGSGetWorkspace) and CGEvent keyboard simulation.

Environment: macOS (Sonoma/Sequoia). No App Sandbox.

2. OPERATIONAL CONSTRAINTS (STRICT)
1. No Xcode GUI Interaction:

You cannot interact with Xcode. You are a CLI-based agent.

FORBIDDEN: Editing .xcodeproj or .pbproj files directly.

MANDATORY: You must use XcodeGen. You will edit a project.yml file and generate the project.

2. Toolchain & Build System:

Generator: xcodegen (Must be installed).

Build: xcodebuild (via Makefile).

Formatting: swiftlint (optional but recommended).

3. File System Structure:

/project.yml -> The project definition.

/Makefile -> The build command center.

/Sources/ -> All Swift code.

/Resources/ -> Plists and Entitlements.

3. ARCHITECTURE
   3.1 Data Flow
   Input (Global Hotkey) -> FloatingPanel -> Query Manager -> (Adapter) -> System

3.2 Component Layering
Presentation (SwiftUI):

SpaceLauncher: Main entry point.

FloatingPanel: A customized NSPanel (non-activating, HUD style).

OmniBoxView: The SwiftUI view for text input and list results.

Domain:

SpaceService: Protocol defining getSpaces(), renameSpace(), switchTo(space).

Infrastructure (Adapters):

YabaiAdapter: Shells out to yabai binary.

NativeAdapter: Bridges to C-based Private APIs.

4. IMPLEMENTATION KNOWLEDGE BASE
   4.1 Project Configuration (project.yml)
   DO NOT HALLUCINATE THE CONFIG. Use this exact baseline to ensure Private APIs and Background execution work.

YAML

name: SpaceCommand
options:
bundleIdPrefix: com.SpaceCommand
targets:
SpaceCommand:
type: application
platform: macOS
deploymentTarget: "14.0"
sources: [Sources]
settings: # CRITICAL: Allows floating UI without dock icon
INFOPLIST_KEY_LSUIElement: true # CRITICAL: Disables Sandbox for CLI/Private API access
ENABLE_USER_SCRIPT_SANDBOXING: NO
com.apple.security.app-sandbox: NO # CRITICAL: Links the Bridging Header for Native Mode
SWIFT_OBJC_BRIDGING_HEADER: Sources/Bridging-Header.h
OTHER_LDFLAGS: "-framework Carbon -framework CoreGraphics"
dependencies: - sdk: SwiftUI.framework - sdk: Carbon.framework
4.2 Yabai Integration (Mode 1)
Detection: Check if yabai exists in path and the socket is open.

Commands:

List spaces: yabai -m query --spaces (Returns JSON).

Focus space: yabai -m space --focus <LABEL_OR_INDEX>.

Label space: yabai -m space <INDEX> --label <NAME>.

4.3 Native Private APIs (Mode 2)
You cannot access space information via public APIs. You must bridge CoreGraphics private headers.

The Bridging Header (Sources/Bridging-Header.h):

C

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Private API definitions
typedef int CGSConnectionID;
extern CGSConnectionID \_CGSDefaultConnection(void);
extern CGError CGSGetWorkspace(CGSConnectionID cid, int \*workspace);
The Swift Implementation:

Swift

// Reading current space
var workspace: Int32 = 0
let connection = \_CGSDefaultConnection()
CGSGetWorkspace(connection, &workspace)
// Note: 'workspace' is the internal ID, not necessarily the display index.
Switching Spaces (Native): Do not try to use CGSSetWorkspace (it is broken/protected in modern macOS).

Strategy: Map Space Names to Index Numbers (1-9).

Action: Simulate Ctrl + <Number> keystrokes.

Code: Use CGEvent(keyboardEventSource: ...) with .maskControl.

5. EXECUTION PLAN
   Phase 1: Skeleton & Build Loop
   Initialize git.

Create project.yml (using the snippet above).

Create Makefile (gen, build, run).

Create Sources/App.swift (Hello World).

Verify: Run make gen && make build.

Phase 2: The Floating UI
Implement FloatingPanel subclass of NSPanel.

Set styleMask = [.borderless, .nonactivatingPanel].

Set collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary].

Create OmniBoxView (SwiftUI).

Verify: App launches a floating bar on top of other windows.

Phase 3: Global Hotkeys
Add Carbon framework dependency (already in yml).

Register a global EventHotKey (e.g., Cmd+Shift+Space).

On press: NSApp.activate(ignoringOtherApps: true) and show panel.

Phase 4: Yabai Adapter
Create ShellRunner helper (using Process).

Implement YabaiAdapter adhering to SpaceService protocol.

Parse JSON output from yabai.

Phase 5: Native Fallback
Create Bridging-Header.h.

Implement NativeAdapter.

Implement KeyboardSimulator for switching.

Implement PersistenceManager (JSON) to save Space Names locally (since we can't store them in Yabai).

6. DEFINITION OF DONE
   User presses Hotkey -> Bar appears.

User types "Deep Work" -> App saves name for current space.

User moves to another space, presses Hotkey.

User types "Deep" -> Fuzzy search shows "Deep Work".

User hits Enter -> Screen switches to "Deep Work" space.

Works with Yabai running.

Works with Yabai stopped (Native fallback).
