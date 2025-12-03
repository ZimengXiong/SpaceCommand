//
//  Bridging-Header.h
//  SpaceCommand
//
//  Private CoreGraphics/SkyLight APIs for native macOS Spaces support
//

#ifndef Bridging_Header_h
#define Bridging_Header_h

#import <Foundation/Foundation.h>

// CoreGraphics Server (CGS) Private APIs for Space Management

/// Returns the default connection to the window server
int _CGSDefaultConnection(void);

/// Returns an array of dictionaries describing all managed display spaces
/// Each display dictionary contains:
///   - "Display Identifier": String
///   - "Current Space": Dictionary with "ManagedSpaceID" key
///   - "Spaces": Array of space dictionaries, each with:
///       - "ManagedSpaceID": Int
///       - "TileLayoutManager": Dictionary (present if fullscreen app)
///       - "pid": pid_t (for fullscreen apps)
id CGSCopyManagedDisplaySpaces(int conn);

/// Returns the display identifier for the active menu bar
id CGSCopyActiveMenuBarDisplayIdentifier(int conn);

/// Adds windows to a specific space
void CGSAddWindowsToSpaces(int cid, CFArrayRef windows, CFArrayRef spaces);

/// Removes windows from specific spaces
void CGSRemoveWindowsFromSpaces(int cid, CFArrayRef windows, CFArrayRef spaces);

/// Move a specific space (reorder spaces)
void CGSMoveSpaceToDisplay(int cid, int spaceId, int displayId);

// SkyLight framework functions for space switching
// These require linking against SkyLight.framework or using dynamic lookup

/// Shows specific spaces (used for space switching)
extern void SLSShowSpaces(int cid, CFArrayRef spaces);

/// Hides specific spaces
extern void SLSHideSpaces(int cid, CFArrayRef spaces);

/// Moves windows to a space
extern void SLSMoveWindowsToManagedSpace(int cid, CFArrayRef windows, int spaceId);

/// Sets a window's list of tags/levels
extern void SLSSetWindowTags(int cid, uint32_t windowId, uint32_t *tags, int tagSize);

/// Alternative space focusing mechanism
extern void SLSSpaceSwitchTo(int cid, int spaceId);

#endif /* Bridging_Header_h */
