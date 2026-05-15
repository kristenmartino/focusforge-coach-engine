import Foundation

/// Tags a reflection template with what kind of advice it offers. Useful for
/// analytics and for downstream UIs that want to color-code or icon-code tips.
public enum ReflectionCategory: String, Codable, Sendable {
    /// Tips about pacing, session length, scheduling.
    case timeManagement
    /// Tips about showing up, building the habit, returning tomorrow.
    case consistency
    /// Tips about breaks, hydration, eye rest, stretching.
    case selfCare
    /// Tips that celebrate or reinforce a winning streak.
    case momentum
}
