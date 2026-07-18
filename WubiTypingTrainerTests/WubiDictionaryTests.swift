import XCTest
@testable import WubiTypingTrainer

@MainActor
final class WubiDictionaryTests: XCTestCase {
    func testSharedInstance() {
        let dict = WubiDictionary.shared
        XCTAssertNotNil(dict)
    }

    func testLoadBuiltinDict() {
        let dict = WubiDictionary.shared
        let result = dict.loadBuiltin()
        XCTAssertTrue(result)
        XCTAssertTrue(dict.isLoaded)
        XCTAssertGreaterThan(dict.count, 0)
    }

    func testLookupKnownChar() {
        let dict = WubiDictionary.shared
        dict.loadBuiltin()
        let code = dict.code(for: "一")
        XCTAssertNotNil(code)
    }

    func testLookupUnknownChar() {
        let dict = WubiDictionary.shared
        dict.loadBuiltin()
        let code = dict.code(for: "\u{20000}")
        XCTAssertNil(code)
    }

    func testCodesForText() {
        let dict = WubiDictionary.shared
        dict.loadBuiltin()
        let results = dict.codes(for: "五笔")
        XCTAssertEqual(results.count, 2)
        for (char, code) in results {
            XCTAssertFalse(char.isWhitespace)
            if code == nil {
                XCTFail("Missing code for character: \(char)")
            }
        }
    }

    func testAllCharsNotEmpty() {
        let dict = WubiDictionary.shared
        dict.loadBuiltin()
        XCTAssertGreaterThan(dict.allChars.count, 1000)
    }
}
