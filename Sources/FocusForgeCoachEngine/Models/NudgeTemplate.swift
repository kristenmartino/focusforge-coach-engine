import Foundation

/// A streak-rescue nudge template. Routes on streak length (`streakTier`) so
/// new-streak users see different copy than 100-day veterans.
///
/// Nudges are intended to be shown either in-app (e.g. a banner) or as a
/// local notification near the streak-loss window — the host app decides
/// presentation.
public struct NudgeTemplate: Codable, Sendable, Identifiable {
    /// Stable identifier (e.g. `nud_mid_01`).
    public let id: String

    /// The streak-day range this template applies to. Templates with
    /// overlapping ranges are all candidates; the engine picks one at random
    /// (with recent-template deduplication).
    public let streakTier: ClosedRange<Int>

    /// Per-tone nudge title. Maps directly to the notification title or
    /// banner heading.
    public let title: [CoachTone: String]

    /// Per-tone nudge body. The current streak length is interpolated via
    /// `%d`.
    public let body: [CoachTone: String]

    public init(
        id: String,
        streakTier: ClosedRange<Int>,
        title: [CoachTone: String],
        body: [CoachTone: String]
    ) {
        self.id = id
        self.streakTier = streakTier
        self.title = title
        self.body = body
    }
}
