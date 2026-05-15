import XCTest
@testable import FocusForgeCoachEngine

final class InMemoryTemplateHistoryTests: XCTestCase {

    func test_recentTemplateIDs_emptyByDefault() {
        let history = InMemoryTemplateHistory()
        XCTAssertEqual(history.recentTemplateIDs(featureType: .framing, limit: 5).count, 0)
    }

    func test_recordShown_appearsInRecentSet() {
        let history = InMemoryTemplateHistory()
        history.recordShown(templateID: "frm_gen_01", featureType: .framing)
        let ids = history.recentTemplateIDs(featureType: .framing, limit: 5)
        XCTAssertTrue(ids.contains("frm_gen_01"))
    }

    func test_recordShown_scopesByFeatureType() {
        let history = InMemoryTemplateHistory()
        history.recordShown(templateID: "frm_gen_01", featureType: .framing)
        let reflectionIDs = history.recentTemplateIDs(featureType: .reflection, limit: 5)
        XCTAssertFalse(reflectionIDs.contains("frm_gen_01"))
    }

    func test_recentTemplateIDs_respectsLimit() {
        let history = InMemoryTemplateHistory()
        for i in 0..<10 {
            history.recordShown(templateID: "frm_test_\(i)", featureType: .framing)
        }
        let ids = history.recentTemplateIDs(featureType: .framing, limit: 3)
        XCTAssertEqual(ids.count, 3)
    }

    func test_recentTemplateIDs_returnsMostRecent() {
        let history = InMemoryTemplateHistory()
        history.recordShown(templateID: "old", featureType: .framing)
        history.recordShown(templateID: "newer", featureType: .framing)
        history.recordShown(templateID: "newest", featureType: .framing)
        let ids = history.recentTemplateIDs(featureType: .framing, limit: 2)
        XCTAssertTrue(ids.contains("newest"))
        XCTAssertTrue(ids.contains("newer"))
        XCTAssertFalse(ids.contains("old"))
    }

    func test_recordShown_capsAtMaxEntries() {
        let history = InMemoryTemplateHistory(maxEntries: 3)
        for i in 0..<10 {
            history.recordShown(templateID: "t\(i)", featureType: .framing)
        }
        let all = history.recentTemplateIDs(featureType: .framing, limit: 100)
        XCTAssertEqual(all.count, 3, "Should only retain maxEntries")
    }

    func test_reset_clearsHistory() {
        let history = InMemoryTemplateHistory()
        history.recordShown(templateID: "x", featureType: .nudge)
        history.reset()
        XCTAssertEqual(history.recentTemplateIDs(featureType: .nudge, limit: 5).count, 0)
    }
}
