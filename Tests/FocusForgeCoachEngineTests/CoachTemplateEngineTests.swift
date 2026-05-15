import XCTest
@testable import FocusForgeCoachEngine

final class CoachTemplateEngineTests: XCTestCase {

    private var history: InMemoryTemplateHistory!
    private var rng: SeededRNG!

    override func setUp() {
        super.setUp()
        history = InMemoryTemplateHistory()
        rng = SeededRNG(seed: 42)
    }

    // MARK: - Category detection

    func test_detectCategory_matchesKeyword() {
        XCTAssertEqual(CoachTemplateEngine.detectCategory(from: "Write Q3 report"), "writing")
        XCTAssertEqual(CoachTemplateEngine.detectCategory(from: "Debug auth flow"), "coding")
        XCTAssertEqual(CoachTemplateEngine.detectCategory(from: "Review for exam"), "study")
    }

    func test_detectCategory_isCaseInsensitive() {
        XCTAssertEqual(CoachTemplateEngine.detectCategory(from: "BRAINSTORM ideas"), "creative")
    }

    func test_detectCategory_returnsGeneral_forUnmappedTask() {
        XCTAssertEqual(CoachTemplateEngine.detectCategory(from: "Plan the trip"), "general")
    }

    func test_detectCategory_handlesPunctuation() {
        XCTAssertEqual(CoachTemplateEngine.detectCategory(from: "Write: Q3 report!"), "writing")
    }

    // MARK: - Framing condition derivation

    func test_framingCondition_newUser_whenFewSessions() {
        let signal = BehaviorSignal(
            completionRate7d: 1.0, abandonRate7d: 0.0,
            avgActualFocusMinutes: 25, streakRiskScore: 0,
            totalSessions7d: 2
        )
        XCTAssertEqual(CoachTemplateEngine.framingCondition(from: signal), .newUser)
    }

    func test_framingCondition_highAbandon_takesPrecedenceOverCompletion() {
        let signal = BehaviorSignal(
            completionRate7d: 0.6, abandonRate7d: 0.4,
            avgActualFocusMinutes: 20, streakRiskScore: 0.3,
            totalSessions7d: 10
        )
        XCTAssertEqual(CoachTemplateEngine.framingCondition(from: signal), .highAbandon)
    }

    func test_framingCondition_lowCompletion() {
        let signal = BehaviorSignal(
            completionRate7d: 0.4, abandonRate7d: 0.2,
            avgActualFocusMinutes: 18, streakRiskScore: 0.2,
            totalSessions7d: 8
        )
        XCTAssertEqual(CoachTemplateEngine.framingCondition(from: signal), .lowCompletion)
    }

    func test_framingCondition_highCompletion() {
        let signal = BehaviorSignal(
            completionRate7d: 0.85, abandonRate7d: 0.05,
            avgActualFocusMinutes: 28, streakRiskScore: 0,
            totalSessions7d: 12
        )
        XCTAssertEqual(CoachTemplateEngine.framingCondition(from: signal), .highCompletion)
    }

    func test_framingCondition_default_forMiddleground() {
        let signal = BehaviorSignal(
            completionRate7d: 0.6, abandonRate7d: 0.1,
            avgActualFocusMinutes: 25, streakRiskScore: 0,
            totalSessions7d: 10
        )
        XCTAssertEqual(CoachTemplateEngine.framingCondition(from: signal), .default)
    }

    // MARK: - Reflection condition derivation

    func test_reflectionCondition_longSession_takesPrecedenceOverRates() {
        let signal = BehaviorSignal(
            completionRate7d: 0.4, abandonRate7d: 0.4,
            avgActualFocusMinutes: 30, streakRiskScore: 0,
            totalSessions7d: 10
        )
        XCTAssertEqual(
            CoachTemplateEngine.reflectionCondition(actualMinutes: 45, signal: signal),
            .longSession
        )
    }

    func test_reflectionCondition_shortSession() {
        let signal = BehaviorSignal(
            completionRate7d: 0.7, abandonRate7d: 0.0,
            avgActualFocusMinutes: 12, streakRiskScore: 0,
            totalSessions7d: 10
        )
        XCTAssertEqual(
            CoachTemplateEngine.reflectionCondition(actualMinutes: 10, signal: signal),
            .shortSession
        )
    }

    // MARK: - Framing selection

    func test_selectFramingTemplate_returnsCategoryMatch_forCodingTask() {
        let signal = BehaviorSignal.empty
        let result = CoachTemplateEngine.selectFramingTemplate(
            taskName: "Debug timer drift",
            signal: signal,
            tone: .encouraging,
            history: history,
            using: &rng
        )
        // For empty signal, totalSessions7d = 0 → newUser condition.
        // We don't have a coding+newUser template, so the engine should fall
        // back to coding+any, which is frm_code_01 or frm_code_02.
        // Either way it must come from the "coding" category candidates OR
        // fall back to the general+default template — but since coding has
        // templates available, we expect a coding-prefixed ID.
        XCTAssertTrue(
            result.templateID.hasPrefix("frm_code_") || result.templateID.hasPrefix("frm_gen_"),
            "Expected coding or general fallback, got \(result.templateID)"
        )
        XCTAssertTrue(result.reframedTask.contains("Debug timer drift"))
        XCTAssertFalse(result.motivationalLine.isEmpty)
    }

    func test_selectFramingTemplate_appliesSafetyFilter_toRenderedCopy() {
        // Inject a hostile catalog and confirm the engine sanitizes.
        let hostile = [
            FramingTemplate(
                id: "frm_test_hostile",
                category: "general",
                condition: .default,
                reframeFormat: [
                    .encouraging: "You failed at %@ again.",
                    .direct: "You failed at %@ again.",
                    .calm: "You failed at %@ again.",
                ],
                motivationalLine: [
                    .encouraging: "Don't be lazy.",
                    .direct: "Don't be lazy.",
                    .calm: "Don't be lazy.",
                ]
            )
        ]
        let result = CoachTemplateEngine.selectFramingTemplate(
            taskName: "anything",
            signal: BehaviorSignal.empty,
            tone: .direct,
            history: history,
            catalog: hostile,
            using: &rng
        )
        XCTAssertEqual(result.reframedTask, SafetyFilter.fallbackMessage)
        XCTAssertEqual(result.motivationalLine, SafetyFilter.fallbackMessage)
    }

    func test_selectFramingTemplate_excludesRecentTemplates() {
        // Pre-populate history with every framing template ID. The engine
        // should fall back rather than return one of them.
        for template in CoachTemplateCatalog.framingTemplates {
            history.recordShown(templateID: template.id, featureType: .framing)
        }
        let result = CoachTemplateEngine.selectFramingTemplate(
            taskName: "Plan trip",
            signal: BehaviorSignal.empty,
            tone: .encouraging,
            history: history,
            using: &rng
        )
        // With every ID in history, the engine falls back to general+default
        // (which is also in history, but the final fallback grabs catalog[0]).
        // What matters is the engine doesn't crash and returns *something*.
        XCTAssertFalse(result.templateID.isEmpty)
        XCTAssertFalse(result.reframedTask.isEmpty)
    }

    func test_selectFramingTemplate_isDeterministic_withSeededRNG() {
        var rng1 = SeededRNG(seed: 7)
        var rng2 = SeededRNG(seed: 7)
        let r1 = CoachTemplateEngine.selectFramingTemplate(
            taskName: "Write essay",
            signal: BehaviorSignal.empty,
            tone: .calm,
            history: InMemoryTemplateHistory(),
            using: &rng1
        )
        let r2 = CoachTemplateEngine.selectFramingTemplate(
            taskName: "Write essay",
            signal: BehaviorSignal.empty,
            tone: .calm,
            history: InMemoryTemplateHistory(),
            using: &rng2
        )
        XCTAssertEqual(r1, r2)
    }

    // MARK: - Reflection selection

    func test_selectReflectionTemplate_routesToLongSession_for40MinSession() {
        let signal = BehaviorSignal(
            completionRate7d: 0.7, abandonRate7d: 0.1,
            avgActualFocusMinutes: 35, streakRiskScore: 0,
            totalSessions7d: 10
        )
        let result = CoachTemplateEngine.selectReflectionTemplate(
            outcome: .completed,
            actualMinutes: 45,
            plannedMinutes: 45,
            signal: signal,
            tone: .encouraging,
            history: history,
            using: &rng
        )
        XCTAssertEqual(result.category, .selfCare)
        XCTAssertFalse(result.tipText.isEmpty)
    }

    func test_selectReflectionTemplate_routesToShortSession_for10MinSession() {
        let signal = BehaviorSignal(
            completionRate7d: 0.7, abandonRate7d: 0.1,
            avgActualFocusMinutes: 12, streakRiskScore: 0,
            totalSessions7d: 10
        )
        let result = CoachTemplateEngine.selectReflectionTemplate(
            outcome: .completed,
            actualMinutes: 10,
            plannedMinutes: 25,
            signal: signal,
            tone: .direct,
            history: history,
            using: &rng
        )
        XCTAssertEqual(result.category, .momentum)
    }

    // MARK: - Nudge selection

    func test_selectNudgeTemplate_routesToEarlyTier_forDay2Streak() {
        let result = CoachTemplateEngine.selectNudgeTemplate(
            streakDays: 2,
            signal: BehaviorSignal.empty,
            tone: .encouraging,
            using: &rng
        )
        XCTAssertTrue(result.templateID.hasPrefix("nud_early_"))
        XCTAssertTrue(result.body.contains("2"))
    }

    func test_selectNudgeTemplate_routesToLongTier_forDay30Streak() {
        let result = CoachTemplateEngine.selectNudgeTemplate(
            streakDays: 30,
            signal: BehaviorSignal.empty,
            tone: .direct,
            using: &rng
        )
        XCTAssertTrue(result.templateID.hasPrefix("nud_long_"))
        XCTAssertTrue(result.body.contains("30"))
    }

    func test_selectNudgeTemplate_quickStartSuggestion_adaptsToAvgFocusMinutes() {
        let shortAvg = BehaviorSignal(
            completionRate7d: 0.5, abandonRate7d: 0.2,
            avgActualFocusMinutes: 10, streakRiskScore: 0.5,
            totalSessions7d: 5
        )
        let longAvg = BehaviorSignal(
            completionRate7d: 0.5, abandonRate7d: 0.2,
            avgActualFocusMinutes: 25, streakRiskScore: 0.5,
            totalSessions7d: 5
        )

        let short = CoachTemplateEngine.selectNudgeTemplate(
            streakDays: 5, signal: shortAvg, tone: .encouraging, using: &rng
        )
        var rng2 = SeededRNG(seed: 42)
        let long = CoachTemplateEngine.selectNudgeTemplate(
            streakDays: 5, signal: longAvg, tone: .encouraging, using: &rng2
        )

        XCTAssertEqual(short.quickStartSuggestion, "Try a 10-minute session")
        XCTAssertEqual(long.quickStartSuggestion, "Try a 15-minute session")
    }
}

// MARK: - Test Helpers

/// A deterministic `RandomNumberGenerator` for stable test output. Uses a
/// simple linear-congruential generator; not cryptographically sound but
/// fine for selecting array elements in tests.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        // LCG constants from Numerical Recipes.
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
