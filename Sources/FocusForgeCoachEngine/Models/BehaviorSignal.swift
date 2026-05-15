import Foundation

/// A snapshot of the user's recent behavior. The engine reads this to route
/// template selection — e.g. high-abandon users see different framing copy
/// than new users.
///
/// The host app builds this from whatever persistence layer it uses. The
/// package provides ``BehaviorSignalMath`` helpers for the more involved
/// derivations (streak risk score, keyword extraction) but you can fill the
/// struct directly from your own data.
///
/// All rates are 0…1 (not 0…100). Minutes are real minutes, not seconds.
public struct BehaviorSignal: Codable, Equatable, Sendable {
    /// Fraction of started focus sessions in the last 7 days that the user
    /// completed. Range: `0...1`. When the user has zero sessions in the
    /// window, the convention is `0.5` (neutral, not zero).
    public let completionRate7d: Double

    /// Fraction of started focus sessions in the last 7 days that the user
    /// abandoned. Range: `0...1`. With zero sessions in the window the
    /// convention is `0.0`.
    public let abandonRate7d: Double

    /// Average length, in real minutes, of completed focus sessions in the
    /// last 7 days. When the user has zero completed sessions in the window
    /// the convention is `25.0` (default Pomodoro length).
    public let avgActualFocusMinutes: Double

    /// How much of a streak risk the user is currently in, 0 (safe) to 1
    /// (about to lose streak). The streak-rescue nudge fires when this is
    /// high. See ``BehaviorSignalMath/streakRiskScore(currentStreakDays:lastCompletedDate:freezesAvailable:now:calendar:)``.
    public let streakRiskScore: Double

    /// Total sessions (any outcome) in the last 7 days. Used to detect
    /// "new user" condition (`< 3`) which routes to friendlier copy.
    public let totalSessions7d: Int

    /// Up to 3 most-used keywords from the user's recent task names, used
    /// for analytics and personalization. Optional — the engine doesn't
    /// require this for selection.
    public let dominantTaskKeywords: [String]

    public init(
        completionRate7d: Double,
        abandonRate7d: Double,
        avgActualFocusMinutes: Double,
        streakRiskScore: Double,
        totalSessions7d: Int,
        dominantTaskKeywords: [String] = []
    ) {
        self.completionRate7d = completionRate7d
        self.abandonRate7d = abandonRate7d
        self.avgActualFocusMinutes = avgActualFocusMinutes
        self.streakRiskScore = streakRiskScore
        self.totalSessions7d = totalSessions7d
        self.dominantTaskKeywords = dominantTaskKeywords
    }

    /// A neutral, "no data yet" signal — useful as the default before the
    /// user has any sessions.
    public static let empty = BehaviorSignal(
        completionRate7d: 0.5,
        abandonRate7d: 0.0,
        avgActualFocusMinutes: 25.0,
        streakRiskScore: 0.0,
        totalSessions7d: 0,
        dominantTaskKeywords: []
    )
}
