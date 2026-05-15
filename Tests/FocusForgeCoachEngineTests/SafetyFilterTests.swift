import XCTest
@testable import FocusForgeCoachEngine

final class SafetyFilterTests: XCTestCase {

    // MARK: - Passes safe content through

    func test_apply_returnsBenignTextUnchanged() {
        let safe = "Great session! What helped you stay focused?"
        XCTAssertEqual(SafetyFilter.apply(safe), safe)
    }

    func test_apply_returnsEmptyStringUnchanged() {
        XCTAssertEqual(SafetyFilter.apply(""), "")
    }

    // MARK: - Catches banned patterns

    func test_apply_replacesYouFailed_withFallback() {
        let hostile = "Looks like you failed yet again — try harder."
        XCTAssertEqual(SafetyFilter.apply(hostile), SafetyFilter.fallbackMessage)
    }

    func test_apply_catchesPatterns_caseInsensitively() {
        let hostile = "You ARE Lazy. Stop slacking."
        XCTAssertEqual(SafetyFilter.apply(hostile), SafetyFilter.fallbackMessage)
    }

    func test_apply_catchesEmbeddedBannedSubstring() {
        // "pathetic" inside a longer phrase
        let hostile = "Honestly this is pathetic at best."
        XCTAssertEqual(SafetyFilter.apply(hostile), SafetyFilter.fallbackMessage)
    }

    func test_apply_catchesAllListedPatterns() {
        for pattern in SafetyFilter.bannedPatterns {
            let test = "Some text \(pattern) more text"
            XCTAssertEqual(
                SafetyFilter.apply(test),
                SafetyFilter.fallbackMessage,
                "Banned pattern '\(pattern)' was not caught"
            )
        }
    }

    // MARK: - Length cap

    func test_apply_truncatesLongOutput_withEllipsis() {
        let long = String(repeating: "x", count: 500)
        let out = SafetyFilter.apply(long)
        XCTAssertEqual(out.count, SafetyFilter.maxLength)
        XCTAssertTrue(out.hasSuffix("..."))
    }

    func test_apply_preservesContent_atOrBelowMaxLength() {
        let exactlyMax = String(repeating: "y", count: SafetyFilter.maxLength)
        // exactlyMax is 300 chars — at the cap, not above, so it passes
        XCTAssertEqual(SafetyFilter.apply(exactlyMax), exactlyMax)
    }
}
