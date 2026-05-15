import Foundation

/// Buckets the user's behavior signal into a coarse-grained condition the
/// catalog can route on. Each template declares which condition it speaks to;
/// the engine picks the best match given the user's current signal.
///
/// Conditions are deliberately discrete (rather than continuous) to keep the
/// catalog small and authorable. Adding a new condition requires writing copy
/// for it across every relevant template.
public enum TemplateCondition: String, Codable, Sendable {
    /// No special condition. Most templates fall here.
    case `default`
    /// `completionRate7d < 0.5` — the user finishes fewer than half of started sessions.
    case lowCompletion
    /// `abandonRate7d > 0.3` — the user abandons more than 30% of started sessions.
    case highAbandon
    /// `totalSessions7d < 3` — the user has fewer than three sessions in the past week.
    case newUser
    /// `completionRate7d >= 0.8` — the user finishes 80%+ of started sessions.
    case highCompletion
    /// `actualMinutes >= 40` — applies to reflection only, after a long session.
    case longSession
    /// `actualMinutes < 15` — applies to reflection only, after a short session.
    case shortSession
}
