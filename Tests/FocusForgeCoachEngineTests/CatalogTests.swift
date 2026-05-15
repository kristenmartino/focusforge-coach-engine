import XCTest
@testable import FocusForgeCoachEngine

/// Sanity checks on the bundled catalog. Catches obvious authoring slips
/// like missing tones, duplicate IDs, or empty arrays.
final class CatalogTests: XCTestCase {

    func test_framingTemplates_isNonEmpty() {
        XCTAssertFalse(CoachTemplateCatalog.framingTemplates.isEmpty)
    }

    func test_reflectionTemplates_isNonEmpty() {
        XCTAssertFalse(CoachTemplateCatalog.reflectionTemplates.isEmpty)
    }

    func test_nudgeTemplates_isNonEmpty() {
        XCTAssertFalse(CoachTemplateCatalog.nudgeTemplates.isEmpty)
    }

    func test_framingTemplateIDs_areUnique() {
        let ids = CoachTemplateCatalog.framingTemplates.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate framing template IDs")
    }

    func test_reflectionTemplateIDs_areUnique() {
        let ids = CoachTemplateCatalog.reflectionTemplates.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate reflection template IDs")
    }

    func test_nudgeTemplateIDs_areUnique() {
        let ids = CoachTemplateCatalog.nudgeTemplates.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate nudge template IDs")
    }

    func test_everyFramingTemplate_hasCopyForEveryTone() {
        for template in CoachTemplateCatalog.framingTemplates {
            for tone in CoachTone.allCases {
                XCTAssertNotNil(
                    template.reframeFormat[tone],
                    "Framing template \(template.id) missing reframeFormat for tone \(tone)"
                )
                XCTAssertNotNil(
                    template.motivationalLine[tone],
                    "Framing template \(template.id) missing motivationalLine for tone \(tone)"
                )
            }
        }
    }

    func test_everyReflectionTemplate_hasCopyForEveryTone() {
        for template in CoachTemplateCatalog.reflectionTemplates {
            for tone in CoachTone.allCases {
                XCTAssertNotNil(
                    template.tipText[tone],
                    "Reflection template \(template.id) missing tipText for tone \(tone)"
                )
            }
        }
    }

    func test_everyNudgeTemplate_hasCopyForEveryTone() {
        for template in CoachTemplateCatalog.nudgeTemplates {
            for tone in CoachTone.allCases {
                XCTAssertNotNil(
                    template.title[tone],
                    "Nudge template \(template.id) missing title for tone \(tone)"
                )
                XCTAssertNotNil(
                    template.body[tone],
                    "Nudge template \(template.id) missing body for tone \(tone)"
                )
            }
        }
    }

    func test_everyFramingFormat_contains_taskNamePlaceholder() {
        for template in CoachTemplateCatalog.framingTemplates {
            for (tone, format) in template.reframeFormat {
                XCTAssertTrue(
                    format.contains("%@"),
                    "Framing template \(template.id) tone \(tone) missing %@ placeholder for task name"
                )
            }
        }
    }

    func test_everyNudgeBody_contains_dayCountPlaceholder() {
        for template in CoachTemplateCatalog.nudgeTemplates {
            for (tone, body) in template.body {
                XCTAssertTrue(
                    body.contains("%d"),
                    "Nudge template \(template.id) tone \(tone) missing %d placeholder for streak days"
                )
            }
        }
    }

    func test_nudgeStreakTiers_cover_streakDays1Through999() {
        // For every plausible streak length, at least one nudge template
        // should match. Otherwise streak-rescue would have no copy to show.
        for day in 1...50 {
            let matching = CoachTemplateCatalog.nudgeTemplates.filter { $0.streakTier.contains(day) }
            XCTAssertFalse(matching.isEmpty, "No nudge template covers streak day \(day)")
        }
        // Also check the upper boundary the catalog claims to support.
        let matching999 = CoachTemplateCatalog.nudgeTemplates.filter { $0.streakTier.contains(999) }
        XCTAssertFalse(matching999.isEmpty, "No nudge template covers extreme streak day 999")
    }

    func test_keywordCategories_routesKnownWords() {
        XCTAssertEqual(CoachTemplateCatalog.keywordCategories["essay"], "writing")
        XCTAssertEqual(CoachTemplateCatalog.keywordCategories["debug"], "coding")
        XCTAssertEqual(CoachTemplateCatalog.keywordCategories["exam"], "study")
        XCTAssertEqual(CoachTemplateCatalog.keywordCategories["sketch"], "creative")
        XCTAssertEqual(CoachTemplateCatalog.keywordCategories["laundry"], "chores")
    }
}
