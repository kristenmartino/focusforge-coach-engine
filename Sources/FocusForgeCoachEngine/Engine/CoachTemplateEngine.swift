import Foundation

/// Selects a template from the bundled catalog given the user's task and
/// recent behavior, renders it with their preferred tone, and returns the
/// rendered copy.
///
/// The engine is intentionally deterministic-given-inputs except for the
/// final pick among equally-eligible candidates, which uses
/// `randomElement()`. Pass a `RandomNumberGenerator` to the
/// `selectXxx(..., using:)` variants for fully deterministic output (useful
/// in tests).
///
/// **Selection algorithm.** For framing:
/// 1. Detect the task category by scanning the task name against
///    ``CoachTemplateCatalog/keywordCategories``. Unmapped words → `"general"`.
/// 2. Derive a condition from the behavior signal (e.g. `lowCompletion`,
///    `highAbandon`, `newUser`).
/// 3. Filter the catalog for templates matching `(category, condition)`,
///    excluding any IDs in the recent-history set.
/// 4. Pick one at random. If empty, fall back to same category + any
///    condition, then to general + default.
///
/// Reflection and nudge follow the same pattern with their respective
/// condition derivations (see ``reflectionCondition(actualMinutes:signal:)``).
public enum CoachTemplateEngine {

    // MARK: - Intent Framing

    /// Selects a framing template for a pre-session prompt.
    ///
    /// - Parameters:
    ///   - taskName: The user's task description. Categorized via keyword match.
    ///   - signal: Recent behavior. Used to pick a condition variant.
    ///   - tone: The user's tone preference.
    ///   - history: Where to look up (and append to) recently-shown template IDs.
    ///   - catalog: Templates to choose from. Defaults to ``CoachTemplateCatalog/framingTemplates``.
    /// - Returns: A rendered ``FramingResult``. `templateID` identifies which
    ///   template the engine picked so the caller can log it.
    public static func selectFramingTemplate(
        taskName: String,
        signal: BehaviorSignal,
        tone: CoachTone,
        history: TemplateUsageHistory,
        catalog: [FramingTemplate] = CoachTemplateCatalog.framingTemplates
    ) -> FramingResult {
        var rng = SystemRandomNumberGenerator()
        return selectFramingTemplate(
            taskName: taskName,
            signal: signal,
            tone: tone,
            history: history,
            catalog: catalog,
            using: &rng
        )
    }

    /// Deterministic variant of ``selectFramingTemplate(taskName:signal:tone:history:catalog:)``
    /// that takes a `RandomNumberGenerator`. Useful in tests for stable output.
    public static func selectFramingTemplate<RNG: RandomNumberGenerator>(
        taskName: String,
        signal: BehaviorSignal,
        tone: CoachTone,
        history: TemplateUsageHistory,
        catalog: [FramingTemplate] = CoachTemplateCatalog.framingTemplates,
        using rng: inout RNG
    ) -> FramingResult {
        let category = detectCategory(from: taskName)
        let condition = framingCondition(from: signal)
        let recentIDs = history.recentTemplateIDs(featureType: .framing, limit: 3)

        // Find matching templates, excluding recently used.
        let exact = catalog.filter { template in
            template.category == category
                && template.condition == condition
                && !recentIDs.contains(template.id)
        }

        // Fallback ladder: same category any condition, then general defaults,
        // then absolute first template (catalog is asserted non-empty).
        let template = exact.randomElement(using: &rng)
            ?? catalog.filter {
                $0.category == category && !recentIDs.contains($0.id)
            }.randomElement(using: &rng)
            ?? catalog.filter {
                $0.category == "general" && $0.condition == .default
            }.randomElement(using: &rng)
            ?? catalog[0]

        let format = template.reframeFormat[tone] ?? template.reframeFormat[.encouraging] ?? "%@"
        let reframed = SafetyFilter.apply(String(format: format, taskName))
        let motivation = SafetyFilter.apply(
            template.motivationalLine[tone] ?? template.motivationalLine[.encouraging] ?? ""
        )

        return FramingResult(
            templateID: template.id,
            originalTask: taskName,
            reframedTask: reframed,
            motivationalLine: motivation
        )
    }

    // MARK: - Post-Session Reflection

    /// Selects a reflection template for after a session completes (or is
    /// abandoned).
    ///
    /// - Parameters:
    ///   - outcome: How the session ended. Currently informational; reflection
    ///     conditions branch on session length, not outcome.
    ///   - actualMinutes: How long the user actually focused, in minutes.
    ///   - plannedMinutes: How long the user planned to focus. Currently
    ///     unused by the selection algorithm; included for future expansion.
    ///   - signal: Recent behavior signal.
    ///   - tone: The user's tone preference.
    ///   - history: Where to look up recently-shown template IDs.
    ///   - catalog: Templates to choose from. Defaults to bundled.
    public static func selectReflectionTemplate(
        outcome: SessionOutcome,
        actualMinutes: Int,
        plannedMinutes: Int,
        signal: BehaviorSignal,
        tone: CoachTone,
        history: TemplateUsageHistory,
        catalog: [ReflectionTemplate] = CoachTemplateCatalog.reflectionTemplates
    ) -> ReflectionResult {
        var rng = SystemRandomNumberGenerator()
        return selectReflectionTemplate(
            outcome: outcome,
            actualMinutes: actualMinutes,
            plannedMinutes: plannedMinutes,
            signal: signal,
            tone: tone,
            history: history,
            catalog: catalog,
            using: &rng
        )
    }

    /// Deterministic variant taking an explicit RNG.
    public static func selectReflectionTemplate<RNG: RandomNumberGenerator>(
        outcome: SessionOutcome,
        actualMinutes: Int,
        plannedMinutes: Int,
        signal: BehaviorSignal,
        tone: CoachTone,
        history: TemplateUsageHistory,
        catalog: [ReflectionTemplate] = CoachTemplateCatalog.reflectionTemplates,
        using rng: inout RNG
    ) -> ReflectionResult {
        _ = outcome
        _ = plannedMinutes
        let condition = reflectionCondition(actualMinutes: actualMinutes, signal: signal)
        let recentIDs = history.recentTemplateIDs(featureType: .reflection, limit: 3)

        let exact = catalog.filter { template in
            template.condition == condition && !recentIDs.contains(template.id)
        }

        let template = exact.randomElement(using: &rng)
            ?? catalog.filter {
                $0.condition == .default && !recentIDs.contains($0.id)
            }.randomElement(using: &rng)
            ?? catalog.filter { $0.condition == .default }.randomElement(using: &rng)
            ?? catalog[0]

        let text = SafetyFilter.apply(
            template.tipText[tone] ?? template.tipText[.encouraging] ?? ""
        )

        return ReflectionResult(
            templateID: template.id,
            tipText: text,
            category: template.category
        )
    }

    // MARK: - Streak Rescue Nudge

    /// Selects a streak-rescue nudge template. Nudges don't deduplicate
    /// against history (they're rare enough — gated by ``NudgeFrequency``
    /// cooldown — that repetition isn't a concern), so this overload
    /// doesn't take a history parameter.
    public static func selectNudgeTemplate(
        streakDays: Int,
        signal: BehaviorSignal,
        tone: CoachTone,
        catalog: [NudgeTemplate] = CoachTemplateCatalog.nudgeTemplates
    ) -> NudgeResult {
        var rng = SystemRandomNumberGenerator()
        return selectNudgeTemplate(
            streakDays: streakDays,
            signal: signal,
            tone: tone,
            catalog: catalog,
            using: &rng
        )
    }

    /// Deterministic variant.
    public static func selectNudgeTemplate<RNG: RandomNumberGenerator>(
        streakDays: Int,
        signal: BehaviorSignal,
        tone: CoachTone,
        catalog: [NudgeTemplate] = CoachTemplateCatalog.nudgeTemplates,
        using rng: inout RNG
    ) -> NudgeResult {
        let candidates = catalog.filter { $0.streakTier.contains(streakDays) }

        // If the streak day is below any tier (e.g. 0), fall back to the
        // last template in the catalog (highest tier — defensive default).
        let template = candidates.randomElement(using: &rng) ?? catalog.last ?? catalog[0]

        let title = SafetyFilter.apply(
            template.title[tone] ?? template.title[.encouraging] ?? ""
        )
        let bodyFormat = template.body[tone] ?? template.body[.encouraging] ?? "%d days"
        let body = SafetyFilter.apply(String(format: bodyFormat, streakDays))

        let suggestion: String
        if signal.avgActualFocusMinutes < 15 {
            suggestion = "Try a 10-minute session"
        } else {
            suggestion = "Try a 15-minute session"
        }

        return NudgeResult(
            templateID: template.id,
            title: title,
            body: body,
            quickStartSuggestion: suggestion
        )
    }

    // MARK: - Public condition derivation

    /// Derives a ``TemplateCondition`` from a behavior signal for framing.
    /// Exposed publicly so callers can introspect routing decisions for
    /// analytics or debugging.
    public static func framingCondition(from signal: BehaviorSignal) -> TemplateCondition {
        if signal.totalSessions7d < 3 { return .newUser }
        if signal.abandonRate7d > 0.3 { return .highAbandon }
        if signal.completionRate7d < 0.5 { return .lowCompletion }
        if signal.completionRate7d >= 0.8 { return .highCompletion }
        return .default
    }

    /// Derives a ``TemplateCondition`` from `actualMinutes` and a behavior
    /// signal for reflection. Long/short session checks take priority over
    /// rate-based conditions.
    public static func reflectionCondition(
        actualMinutes: Int,
        signal: BehaviorSignal
    ) -> TemplateCondition {
        if signal.totalSessions7d < 3 { return .newUser }
        if actualMinutes >= 40 { return .longSession }
        if actualMinutes < 15 { return .shortSession }
        if signal.abandonRate7d > 0.3 { return .highAbandon }
        if signal.completionRate7d < 0.5 { return .lowCompletion }
        if signal.completionRate7d >= 0.8 { return .highCompletion }
        return .default
    }

    /// Maps a task name to a category bucket by scanning for keywords. Public
    /// so the host app can preview which category a task will route to.
    public static func detectCategory(from taskName: String) -> String {
        let words = taskName.lowercased().components(separatedBy: .alphanumerics.inverted)
        for word in words {
            if let category = CoachTemplateCatalog.keywordCategories[word] {
                return category
            }
        }
        return "general"
    }
}
