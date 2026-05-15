import XCTest
@testable import FocusForgeCoachEngine

final class BehaviorSignalMathTests: XCTestCase {

    // MARK: - Completion / abandon rates

    func test_completionRate_zeroSessions_isNeutral05() {
        XCTAssertEqual(BehaviorSignalMath.completionRate(completed: 0, total: 0), 0.5)
    }

    func test_completionRate_threeOfFour() {
        XCTAssertEqual(
            BehaviorSignalMath.completionRate(completed: 3, total: 4),
            0.75,
            accuracy: 0.0001
        )
    }

    func test_abandonRate_zeroSessions_isZero() {
        XCTAssertEqual(BehaviorSignalMath.abandonRate(abandoned: 0, total: 0), 0.0)
    }

    func test_abandonRate_oneOfFour() {
        XCTAssertEqual(
            BehaviorSignalMath.abandonRate(abandoned: 1, total: 4),
            0.25,
            accuracy: 0.0001
        )
    }

    func test_avgActualFocusMinutes_zeroCompleted_returns25() {
        XCTAssertEqual(BehaviorSignalMath.avgActualFocusMinutes(totalCompletedSeconds: 0, completedCount: 0), 25.0)
    }

    func test_avgActualFocusMinutes_twoTwentyFiveMinSessions() {
        // 2 sessions × 25 min × 60s = 3000 seconds total
        let avg = BehaviorSignalMath.avgActualFocusMinutes(totalCompletedSeconds: 3000, completedCount: 2)
        XCTAssertEqual(avg, 25.0, accuracy: 0.0001)
    }

    // MARK: - Streak risk score

    func test_streakRiskScore_noLastDate_isZero() {
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 5,
            lastCompletedDate: nil,
            freezesAvailable: 0
        )
        XCTAssertEqual(score, 0.0)
    }

    func test_streakRiskScore_completedToday_isZero() {
        let now = Date()
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 7,
            lastCompletedDate: now,
            freezesAvailable: 0,
            now: now
        )
        XCTAssertEqual(score, 0.0)
    }

    func test_streakRiskScore_yesterdayMorning_isLow() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 9))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 5,
            lastCompletedDate: yesterday,
            freezesAvailable: 1,
            now: now,
            calendar: calendar
        )
        // baseRisk 0.1 (morning) + streakBoost 5*0.02=0.1 = 0.2
        XCTAssertEqual(score, 0.2, accuracy: 0.001)
    }

    func test_streakRiskScore_yesterdayEvening_isHigh() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 21))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 5,
            lastCompletedDate: yesterday,
            freezesAvailable: 0,
            now: now,
            calendar: calendar
        )
        // baseRisk 0.3 + (21-18)*0.1 = 0.6, plus streakBoost 0.1 = 0.7
        XCTAssertEqual(score, 0.7, accuracy: 0.001)
    }

    func test_streakRiskScore_twoDaysAgo_withFreeze_isMedium() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 14))!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 5,
            lastCompletedDate: twoDaysAgo,
            freezesAvailable: 1,
            now: now,
            calendar: calendar
        )
        // 0.5 + 0.1 = 0.6
        XCTAssertEqual(score, 0.6, accuracy: 0.001)
    }

    func test_streakRiskScore_twoDaysAgo_noFreeze_isMax() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 14))!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 5,
            lastCompletedDate: twoDaysAgo,
            freezesAvailable: 0,
            now: now,
            calendar: calendar
        )
        // 1.0 + 0.1 streakBoost = 1.1, clamped to 1.0
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
    }

    func test_streakRiskScore_streakBoost_capsAt02() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 9))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let score = BehaviorSignalMath.streakRiskScore(
            currentStreakDays: 100,  // would give 100*0.02 = 2.0, but capped to 0.2
            lastCompletedDate: yesterday,
            freezesAvailable: 1,
            now: now,
            calendar: calendar
        )
        // baseRisk 0.1 (morning) + capped streakBoost 0.2 = 0.3
        XCTAssertEqual(score, 0.3, accuracy: 0.001)
    }

    // MARK: - Keyword extraction

    func test_extractKeywords_picksTopByFrequency() {
        let names = ["Write essay", "Write essay", "Write essay", "Write report"]
        let keywords = BehaviorSignalMath.extractKeywords(from: names)
        XCTAssertEqual(keywords.first, "write")
        // "essay" appears 3 times, should be second-most-common after "write"
        XCTAssertTrue(keywords.contains("essay"))
    }

    func test_extractKeywords_filtersStopWords() {
        let names = ["Write the report on the project", "The deep work session"]
        let keywords = BehaviorSignalMath.extractKeywords(from: names)
        XCTAssertFalse(keywords.contains("the"))
        XCTAssertFalse(keywords.contains("on"))
    }

    func test_extractKeywords_filtersShortWords() {
        let names = ["Do go up", "It is at"]
        let keywords = BehaviorSignalMath.extractKeywords(from: names)
        // All words are <3 chars or stop-words; result is empty.
        XCTAssertEqual(keywords.count, 0)
    }

    func test_extractKeywords_isCaseInsensitive() {
        let names = ["WRITE essay", "Write Essay"]
        let keywords = BehaviorSignalMath.extractKeywords(from: names)
        // Should treat "WRITE"/"Write" and "essay"/"Essay" as the same word.
        XCTAssertTrue(keywords.contains("write"))
        XCTAssertTrue(keywords.contains("essay"))
    }

    func test_extractKeywords_respectsLimit() {
        let names = ["alpha bravo charlie delta echo foxtrot"]
        let keywords = BehaviorSignalMath.extractKeywords(from: names, limit: 2)
        XCTAssertEqual(keywords.count, 2)
    }
}
