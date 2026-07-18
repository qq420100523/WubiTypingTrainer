import XCTest
@testable import WubiTypingTrainer

final class TypingStatsTests: XCTestCase {
    func testAccuracy() {
        let stats = TypingStats(
            elapsedTime: 60,
            correctCount: 45,
            errorCount: 5,
            totalTyped: 50,
            keystrokeCount: 55,
            backspaceCount: 2,
            targetLength: 100
        )
        XCTAssertEqual(stats.formattedAccuracy, "90.0%")
    }

    func testFormattedTime() {
        let stats = TypingStats(
            elapsedTime: 125,
            correctCount: 0,
            errorCount: 0,
            totalTyped: 0,
            keystrokeCount: 0,
            backspaceCount: 0,
            targetLength: 0
        )
        XCTAssertEqual(stats.formattedTime, "2分5秒")
    }

    func testSpeed() {
        let stats = TypingStats(
            elapsedTime: 60,
            correctCount: 30,
            errorCount: 0,
            totalTyped: 30,
            keystrokeCount: 30,
            backspaceCount: 0,
            targetLength: 30
        )
        XCTAssertTrue(stats.formattedSpeed.contains("30"))
    }

    func testZeroElapsed() {
        let stats = TypingStats(
            elapsedTime: 0,
            correctCount: 0,
            errorCount: 0,
            totalTyped: 0,
            keystrokeCount: 0,
            backspaceCount: 0,
            targetLength: 0
        )
        XCTAssertEqual(stats.formattedSpeed, "0.0 字/分")
    }
}
