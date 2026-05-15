import Foundation

/// Pure math helpers for deriving a ``BehaviorSignal`` from raw session data.
///
/// The package can't fetch sessions from your persistence layer — that's the
/// host app's job — but the host can lean on this enum for the algorithmic
/// pieces (completion rates, keyword extraction, streak risk score) so the
/// behavior is identical across consumers and unit-testable in isolation.
public enum BehaviorSignalMath {

    /// Stop words excluded from task-name keyword extraction. Short
    /// connectives and verbs that carry no domain signal.
    public static let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "is", "it", "my", "do", "some", "this",
        "that", "i", "me", "we", "up", "out", "get", "go", "work", "thing",
    ]

    /// Computes a 0…1 completion rate given total and completed counts.
    /// Returns `0.5` (neutral) when `total == 0`.
    public static func completionRate(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0.5 }
        return Double(completed) / Double(total)
    }

    /// Computes a 0…1 abandon rate given abandoned and total counts.
    /// Returns `0.0` when `total == 0`.
    public static func abandonRate(abandoned: Int, total: Int) -> Double {
        guard total > 0 else { return 0.0 }
        return Double(abandoned) / Double(total)
    }

    /// Computes average completed-session minutes from total completed
    /// seconds and completed-session count. Returns `25.0` (default
    /// Pomodoro length) when `completedCount == 0`.
    public static func avgActualFocusMinutes(totalCompletedSeconds: Int, completedCount: Int) -> Double {
        guard completedCount > 0 else { return 25.0 }
        return Double(totalCompletedSeconds) / Double(completedCount) / 60.0
    }

    /// How risky the user's current streak position is, 0 (safe) to 1
    /// (about to lose). The streak-rescue nudge uses this to decide whether
    /// to fire.
    ///
    /// Algorithm:
    /// - **Same-day completion** → 0.0 (safe).
    /// - **No `lastCompletedDate`** (user has never completed a session) → 0.0.
    /// - **Yesterday completion** → 0.1 in the morning, 0.2 in the
    ///   afternoon, then climbs by 0.1 per hour past 18:00.
    /// - **2+ days gap, with freezes available** → 0.5.
    /// - **2+ days gap, no freezes** → 1.0.
    /// - In all cases, longer current streaks add up to +0.2 (saturating
    ///   at 10 days * 0.02) so longer streaks are slightly more protected.
    /// - Final value is clamped to 1.0.
    ///
    /// - Parameters:
    ///   - currentStreakDays: Length of the current streak in days.
    ///   - lastCompletedDate: When the user last completed a focus session.
    ///     `nil` if they never have.
    ///   - freezesAvailable: How many streak freezes the user has banked.
    ///   - now: The current time. Inject for testability; defaults to `.now`.
    ///   - calendar: Calendar to use. Defaults to `.current`.
    public static func streakRiskScore(
        currentStreakDays: Int,
        lastCompletedDate: Date?,
        freezesAvailable: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        guard let lastDate = lastCompletedDate else {
            return 0.0
        }

        let today = calendar.startOfDay(for: now)
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        let currentHour = calendar.component(.hour, from: now)

        if daysBetween <= 0 {
            return 0.0
        }

        var baseRisk: Double

        if daysBetween == 1 {
            if currentHour < 12 {
                baseRisk = 0.1
            } else if currentHour < 18 {
                baseRisk = 0.2
            } else {
                baseRisk = 0.3 + Double(currentHour - 18) * 0.1
            }
        } else {
            if freezesAvailable > 0 {
                baseRisk = 0.5
            } else {
                baseRisk = 1.0
            }
        }

        // Longer streaks earn a small protective boost.
        let streakBoost = min(Double(currentStreakDays) * 0.02, 0.2)
        return min(1.0, baseRisk + streakBoost)
    }

    /// Extracts up to 3 most-used keywords across a list of task name strings,
    /// ignoring stop words and words shorter than 3 characters.
    public static func extractKeywords(from taskNames: [String], limit: Int = 3) -> [String] {
        var wordCounts: [String: Int] = [:]

        for name in taskNames {
            let words = name
                .lowercased()
                .components(separatedBy: .alphanumerics.inverted)
                .filter { $0.count >= 3 && !stopWords.contains($0) }
            for word in words {
                wordCounts[word, default: 0] += 1
            }
        }

        return wordCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }
}
