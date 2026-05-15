import Foundation

/// How often the streak-rescue nudge may be sent. The engine reads
/// ``cooldownSeconds`` and compares against the timestamp of the last delivered
/// nudge to decide whether to send another.
///
/// This is a user preference, not a global throttle — the host app stores the
/// selection and the timestamp of the last sent nudge.
public enum NudgeFrequency: String, Codable, CaseIterable, Sendable {
    /// At most one nudge per 24 hours. Recommended for users who find frequent
    /// reminders aversive.
    case low
    /// At most one nudge per 12 hours. The default.
    case medium
    /// At most one nudge per 6 hours. For users actively building a daily
    /// habit and wanting more aggressive accountability.
    case high

    /// Minimum time that must elapse between two delivered nudges, in seconds.
    public var cooldownSeconds: TimeInterval {
        switch self {
        case .low: 24 * 3600
        case .medium: 12 * 3600
        case .high: 6 * 3600
        }
    }
}
