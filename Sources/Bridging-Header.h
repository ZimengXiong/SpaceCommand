#ifndef Bridging_Header_h
#define Bridging_Header_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Private CoreGraphics API definitions for space management
typedef int CGSConnectionID;

// Get the default connection to the window server
extern CGSConnectionID _CGSDefaultConnection(void);

// Get the current workspace/space number
extern CGError CGSGetWorkspace(CGSConnectionID cid, int *workspace);

// Get the number of workspaces
extern CGError CGSGetNumberOfWorkspaces(CGSConnectionID cid, int *numWorkspaces);

// Managed display spaces (modern API)
extern CFArrayRef CGSCopyManagedDisplaySpaces(CGSConnectionID cid);
extern CFStringRef CGSCopyManagedDisplayForSpace(CGSConnectionID cid, uint64_t spaceId);

#endif /* Bridging_Header_h */
