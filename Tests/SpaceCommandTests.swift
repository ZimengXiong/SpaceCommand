import XCTest

@testable import SpaceCommand

// PersistenceManager tests removed as native mode support is no longer available.

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
