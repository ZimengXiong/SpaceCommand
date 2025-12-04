// Private CoreGraphics APIs for native macOS Spaces support

#ifndef Bridging_Header_h
#define Bridging_Header_h

#import <Foundation/Foundation.h>

// CoreGraphics Server (CGS) Private APIs for Space Management

int _CGSDefaultConnection(void);

id CGSCopyManagedDisplaySpaces(int conn);

#endif /* Bridging_Header_h */
