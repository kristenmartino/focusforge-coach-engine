import Foundation

/// A post-session reflection template. Renders into a single tip shown after
/// the user completes (or abandons) a session.
///
/// Reflection templates branch on ``TemplateCondition`` and also carry a
/// ``ReflectionCategory`` tag for downstream analytics.
public struct ReflectionTemplate: Codable, Sendable, Identifiable {
    /// Stable identifier (e.g. `ref_comp_01`).
    public let id: String

    /// The behavior condition this template targets.
    public let condition: TemplateCondition

    /// Semantic category — what kind of advice this tip offers.
    public let category: ReflectionCategory

    /// Per-tone tip copy. No interpolation — the text is shown as-is.
    public let tipText: [CoachTone: String]

    public init(
        id: String,
        condition: TemplateCondition,
        category: ReflectionCategory,
        tipText: [CoachTone: String]
    ) {
        self.id = id
        self.condition = condition
        self.category = category
        self.tipText = tipText
    }
}
