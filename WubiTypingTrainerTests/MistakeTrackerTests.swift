import XCTest
@testable import WubiTypingTrainer

@MainActor
final class MistakeTrackerTests: XCTestCase {
    func testRecordMistake() {
        let tracker = MistakeTracker()
        tracker.recordMistake(for: "测", code: "imj")
        let mistakes = tracker.sortedMistakes
        XCTAssertEqual(mistakes.count, 1)
        XCTAssertEqual(mistakes[0].char, "测")
        XCTAssertEqual(mistakes[0].count, 1)
    }

    func testRecordCorrectReducesCount() {
        let tracker = MistakeTracker()
        tracker.recordMistake(for: "试", code: "yaa")
        tracker.recordCorrect(for: "试")
        let mistakes = tracker.sortedMistakes
        XCTAssertTrue(mistakes.isEmpty || mistakes[0].count == 0)
    }

    func testClear() {
        let tracker = MistakeTracker()
        tracker.recordMistake(for: "字", code: "pb")
        tracker.clear()
        let mistakes = tracker.sortedMistakes
        XCTAssertTrue(mistakes.isEmpty)
    }

    func testIsEmpty() {
        let tracker = MistakeTracker()
        XCTAssertTrue(tracker.isEmpty)
        tracker.recordMistake(for: "五", code: "gg")
        XCTAssertFalse(tracker.isEmpty)
    }
}
