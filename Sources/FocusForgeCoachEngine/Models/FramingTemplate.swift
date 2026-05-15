import Foundation

/// A pre-session "intent framing" template. Renders into copy like
/// "Let's focus on: Drafting Q3 report. Pick one specific outcome to aim for."
///
/// The engine fills in the user's task name via the `%@` placeholder in
/// ``reframeFormat``. Each template carries copy for every ``CoachTone``.
public struct FramingTemplate: Codable, Sendable, Identifiable {
    /// Stable identifier (e.g. `frm_gen_01`). Used for analytics and for the
    /// engine's deduplication history.
    public let id: String

    /// The task category this template speaks to. Matched against keywords
    /// the engine extracts from the user's task name. See
    /// ``CoachTemplateCatalog/keywordCategories``.
    public let category: String

    /// The behavior condition this template targets.
    public let condition: TemplateCondition

    /// Per-tone format strings. The user's task name is interpolated via `%@`.
    ///
    /// Example:
    /// ```
    /// [.encouraging: "Let's focus on: %@. You've got this!"]
    /// ```
    public let reframeFormat: [CoachTone: String]

    /// Per-tone closing line, shown after the reframed task.
    public let motivationalLine: [CoachTone: String]

    public init(
        id: String,
        category: String,
        condition: TemplateCondition,
        reframeFormat: [CoachTone: String],
        motivationalLine: [CoachTone: String]
    ) {
        self.id = id
        self.category = category
        self.condition = condition
        self.reframeFormat = reframeFormat
        self.motivationalLine = motivationalLine
    }
}
