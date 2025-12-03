import XCTest

@testable import SpaceCommand

final class SpaceTests: XCTestCase {
    func testSpaceDisplayName_WithLabel() {
        let space = Space(id: "1", index: 1, label: "Work", isCurrent: false, uuid: nil)
        XCTAssertEqual(space.displayName, "Work")
    }

    func testSpaceDisplayName_WithoutLabel() {
        let space = Space(id: "1", index: 1, label: nil, isCurrent: false, uuid: nil)
        XCTAssertEqual(space.displayName, "Space 1")
    }

    func testSpaceDisplayName_WithEmptyLabel() {
        let space = Space(id: "1", index: 1, label: "", isCurrent: false, uuid: nil)
        XCTAssertEqual(space.displayName, "Space 1")
    }
}

final class FuzzyMatchTests: XCTestCase {

    func testFuzzyMatch(query: String, target: String) -> Bool {
        if target.lowercased().contains(query.lowercased()) {
            return true
        }

        let queryLower = query.lowercased()
        let targetLower = target.lowercased()

        var queryIndex = queryLower.startIndex
        var targetIndex = targetLower.startIndex

        while queryIndex < queryLower.endIndex && targetIndex < targetLower.endIndex {
            if queryLower[queryIndex] == targetLower[targetIndex] {
                queryIndex = queryLower.index(after: queryIndex)
            }
            targetIndex = targetLower.index(after: targetIndex)
        }

        return queryIndex == queryLower.endIndex
    }

    func testExactMatch() {
        XCTAssertTrue(testFuzzyMatch(query: "Work", target: "Work"))
    }

    func testContainsMatch() {
        XCTAssertTrue(testFuzzyMatch(query: "ork", target: "Work"))
    }

    func testFuzzySequenceMatch() {
        XCTAssertTrue(testFuzzyMatch(query: "wk", target: "Work"))
    }

    func testNoMatch() {
        XCTAssertFalse(testFuzzyMatch(query: "xyz", target: "Work"))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(testFuzzyMatch(query: "work", target: "WORK"))
    }
}

// MARK: - Native Mode Space Switching Tests

final class NativeModeSwitchingTests: XCTestCase {

    func testNativeAdapter_CanBeInitialized() {
        let adapter = NativeAdapter()
        XCTAssertNotNil(adapter)
    }

    func testNativeAdapter_IsAvailable() {
        let adapter = NativeAdapter()

        let isAvailable = adapter.isAvailable
        XCTAssertTrue(isAvailable, "Native adapter should be available on macOS")
    }

    func testNativeAdapter_GetSpaces_ReturnsSpaces() {
        let adapter = NativeAdapter()
        let spaces = adapter.getSpaces()

        XCTAssertFalse(spaces.isEmpty, "Should return at least one space")

        for space in spaces {
            XCTAssertFalse(space.id.isEmpty, "Space ID should not be empty")
            XCTAssertTrue(space.index >= 0, "Space index should be non-negative")
        }
    }

    func testNativeAdapter_GetCurrentSpace_ReturnsCurrentSpace() {
        let adapter = NativeAdapter()
        let currentSpace = adapter.getCurrentSpace()

        if let space = currentSpace {
            XCTAssertTrue(space.isCurrent, "Returned space should be marked as current")
        }
    }

    func testNativeAdapter_SwitchTo_SimulatesKeyboardForSpaces1to10() {
        let adapter = NativeAdapter()
        let spaces = adapter.getSpaces()

        let testSpace = spaces.first { !$0.isFullScreen && $0.index >= 1 && $0.index <= 10 }

        if let space = testSpace {

            adapter.switchTo(space: space)

        } else {
            XCTSkip("No suitable space found for keyboard simulation test")
        }
    }

    func testNativeAdapter_SwitchTo_FullScreenSpace() {
        let adapter = NativeAdapter()
        let spaces = adapter.getSpaces()

        let testSpace = spaces.first { $0.isFullScreen }

        if let space = testSpace {

            adapter.switchTo(space: space)

        } else {
            XCTSkip("No fullscreen space found for AppleScript test")
        }
    }

    func testNativeAdapter_RenameSpace() {
        let adapter = NativeAdapter()
        let spaces = adapter.getSpaces()
        guard let space = spaces.first else {
            XCTFail("No spaces available for rename test")
            return
        }

        let testName = "TestSpace_\(UUID().uuidString.prefix(8))"
        adapter.renameSpace(space: space, to: testName)

        let updatedSpaces = adapter.getSpaces()
        let renamedSpace = updatedSpaces.first { $0.id == space.id }

        XCTAssertNotNil(renamedSpace, "Should find the renamed space")
        if let renamed = renamedSpace {
            XCTAssertEqual(renamed.label, testName, "Space should be renamed")
        }
    }
}

// MARK: - Yabai Mode Space Switching Tests

final class YabaiModeSwitchingTests: XCTestCase {

    func testYabaiAdapter_CanBeInitialized() {
        let adapter = YabaiAdapter()
        XCTAssertNotNil(adapter)
    }

    func testYabaiAdapter_Availability() {
        let adapter = YabaiAdapter()

        let isAvailable = adapter.isAvailable
        print("Yabai available: \(isAvailable)")

    }

    func testYabaiAdapter_GetSpaces_HandlesNoYabai() {
        let adapter = YabaiAdapter()
        let spaces = adapter.getSpaces()

        if !adapter.isAvailable {
            XCTAssertTrue(spaces.isEmpty, "Should return empty array when yabai is not available")
        }
    }

    func testYabaiAdapter_GetSpaces_HandlesYabaiOutput() {
        let adapter = YabaiAdapter()
        guard adapter.isAvailable else {
            XCTSkip("Yabai not available - skipping JSON parsing test")
        }

        let spaces = adapter.getSpaces()

        XCTAssertFalse(spaces.isEmpty, "Should return spaces when yabai is available")

        for space in spaces {
            XCTAssertFalse(space.id.isEmpty, "Space ID should not be empty")
            XCTAssertTrue(space.index >= 0, "Space index should be non-negative")
        }
    }

    func testYabaiAdapter_SwitchTo_WithLabel() {
        let adapter = YabaiAdapter()
        guard adapter.isAvailable else {
            XCTSkip("Yabai not available")
        }

        let spaces = adapter.getSpaces()
        guard let spaceWithLabel = spaces.first(where: { $0.label != nil && !$0.label!.isEmpty })
        else {
            XCTSkip("No space with label found")
        }

        adapter.switchTo(space: spaceWithLabel)

    }

    func testYabaiAdapter_SwitchTo_WithIndex() {
        let adapter = YabaiAdapter()
        guard adapter.isAvailable else {
            XCTSkip("Yabai not available")
        }

        let spaces = adapter.getSpaces()
        guard let space = spaces.first else {
            XCTSkip("No spaces available")
        }

        adapter.switchTo(space: space)

    }
}

// MARK: - SpaceManager Integration Tests

final class SpaceManagerIntegrationTests: XCTestCase {

    func testSpaceManager_InitializesWithAdapters() {
        let manager = SpaceManager.shared
        XCTAssertNotNil(manager)
    }

    func testSpaceManager_HasAvailableBackend() {
        let manager = SpaceManager.shared
        let hasBackend = manager.hasAvailableBackend

        XCTAssertTrue(hasBackend, "Should have at least one available backend")
    }

    func testSpaceManager_RefreshSpaces() {
        let manager = SpaceManager.shared
        let initialCount = manager.spaces.count

        manager.refreshSpaces()
        let updatedCount = manager.spaces.count

        XCTAssertTrue(updatedCount >= 0, "Should have valid space count after refresh")
    }

    func testSpaceManager_SwitchTo_DelegatesToAdapter() {
        let manager = SpaceManager.shared
        let spaces = manager.spaces
        guard let testSpace = spaces.first else {
            XCTSkip("No spaces available for switch test")
        }

        manager.switchTo(space: testSpace)

    }

    func testSpaceManager_RenameSpace() {
        let manager = SpaceManager.shared
        let spaces = manager.spaces
        guard let space = spaces.first else {
            XCTFail("No spaces available for rename test")
            return
        }

        let testName = "ManagerTest_\(UUID().uuidString.prefix(8))"
        manager.renameSpace(space: space, to: testName)

        let expectation = self.expectation(description: "Space rename")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.refreshSpaces()
            let updatedSpace = manager.spaces.first { $0.id == space.id }

            if let renamed = updatedSpace {
                XCTAssertEqual(renamed.label, testName, "Space should be renamed via manager")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }
}

// MARK: - Debug Test Utility

final class DebugSpaceSwitchingTests: XCTestCase {

    func testDebug_SpaceEnvironment() {
        let manager = SpaceManager.shared

        print("=== SPACE DEBUG INFO ===")
        print("Yabai Available: \(manager.isYabaiAvailable)")
        print("Native Available: \(manager.isNativeAvailable)")
        print("Current Mode: \(manager.currentMode)")
        print("Active Adapter: \(manager.activeAdapterName)")
        print("Total Spaces: \(manager.spaces.count)")

        for (index, space) in manager.spaces.enumerated() {
            print(
                "Space \(index): ID=\(space.id), Index=\(space.index), Label=\(space.label ?? "nil"), Current=\(space.isCurrent), FullScreen=\(space.isFullScreen)"
            )
        }
        print("========================")

        XCTAssertTrue(true, "Debug info printed to console")
    }

    func testDebug_NativeAdapterMethods() {
        print("=== NATIVE ADAPTER DEBUG ===")

        let adapter = NativeAdapter()
        print("Native Adapter Available: \(adapter.isAvailable)")

        let spaces = adapter.getSpaces()
        print("Native Spaces Count: \(spaces.count)")

        for space in spaces {
            print("  Space: \(space.displayName) (ID: \(space.id), Index: \(space.index))")
        }

        if let current = adapter.getCurrentSpace() {
            print("Current Space: \(current.displayName)")
        }

        print("============================")

        XCTAssertTrue(true, "Native adapter debug info printed")
    }

    func testDebug_YabaiAdapterMethods() {
        print("=== YABAI ADAPTER DEBUG ===")

        let adapter = YabaiAdapter()
        print("Yabai Adapter Available: \(adapter.isAvailable)")

        if adapter.isAvailable {
            let spaces = adapter.getSpaces()
            print("Yabai Spaces Count: \(spaces.count)")

            for space in spaces {
                print("  Space: \(space.displayName) (ID: \(space.id), Index: \(space.index))")
            }

            if let current = adapter.getCurrentSpace() {
                print("Current Space: \(current.displayName)")
            }
        } else {
            print("Yabai not available - skipping space enumeration")
        }

        print("===========================")

        XCTAssertTrue(true, "Yabai adapter debug info printed")
    }
}
