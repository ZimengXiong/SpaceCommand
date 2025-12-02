import XCTest

@testable import SpaceCommand

final class PersistenceManagerTests: XCTestCase {
    var persistenceManager: PersistenceManager!
    var testFileURL: URL!

    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager()
    }

    override func tearDown() {
        // Clean up test data
        super.tearDown()
    }

    func testSaveAndLoadSpaceName() {
        // Save a space name
        persistenceManager.saveSpaceName(index: 1, name: "Test Space")

        // Load and verify
        let names = persistenceManager.loadSpaceNames()
        XCTAssertEqual(names["1"], "Test Space")
    }

    func testSaveMultipleSpaceNames() {
        persistenceManager.saveSpaceName(index: 1, name: "Work")
        persistenceManager.saveSpaceName(index: 2, name: "Personal")
        persistenceManager.saveSpaceName(index: 3, name: "Gaming")

        let names = persistenceManager.loadSpaceNames()
        XCTAssertEqual(names["1"], "Work")
        XCTAssertEqual(names["2"], "Personal")
        XCTAssertEqual(names["3"], "Gaming")
    }

    func testOverwriteSpaceName() {
        persistenceManager.saveSpaceName(index: 1, name: "Old Name")
        persistenceManager.saveSpaceName(index: 1, name: "New Name")

        let names = persistenceManager.loadSpaceNames()
        XCTAssertEqual(names["1"], "New Name")
    }

    func testRemoveSpaceName() {
        persistenceManager.saveSpaceName(index: 1, name: "To Remove")
        persistenceManager.removeSpaceName(index: 1)

        let names = persistenceManager.loadSpaceNames()
        XCTAssertNil(names["1"])
    }
}

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
    // Test the fuzzy matching logic
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
