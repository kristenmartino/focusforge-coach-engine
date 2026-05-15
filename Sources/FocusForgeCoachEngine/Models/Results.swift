import Foundation

/// The rendered output of an intent-framing selection. Pass directly to your
/// pre-session UI.
///
/// Conforms to `Identifiable` (via a per-instance UUID) so consumers can
/// drive a SwiftUI `.sheet(item:)` presentation off the result directly.
/// The `id` is unique to each engine call, not to the template — so two
/// successive calls that happen to pick the same template will re-trigger
/// the sheet.
public struct FramingResult: Equatable, Sendable, Identifiable {
    /// Per-presentation unique identifier. Used by SwiftUI sheet/item
    /// presentation to identify *which* result is being shown. Never log
    /// or persist this id — use ``templateID`` for analytics.
    public let id: UUID
    /// The selected template's stable id. Log this in analytics so you can
    /// trace which copy a user saw.
    public let templateID: String
    /// The task name the user supplied, echoed back unchanged.
    public let originalTask: String
    /// The reframed task copy with the user's task name interpolated and the
    /// safety filter applied.
    public let reframedTask: String
    /// The motivational closing line with safety filter applied.
    public let motivationalLine: String

    public init(
        id: UUID = UUID(),
        templateID: String,
        originalTask: String,
        reframedTask: String,
        motivationalLine: String
    ) {
        self.id = id
        self.templateID = templateID
        self.originalTask = originalTask
        self.reframedTask = reframedTask
        self.motivationalLine = motivationalLine
    }
}

/// The rendered output of a post-session reflection selection.
///
/// Conforms to `Identifiable` via a per-instance UUID for sheet/item
/// SwiftUI presentations. See ``FramingResult`` for the rationale.
public struct ReflectionResult: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let templateID: String
    public let tipText: String
    public let category: ReflectionCategory

    public init(
        id: UUID = UUID(),
        templateID: String,
        tipText: String,
        category: ReflectionCategory
    ) {
        self.id = id
        self.templateID = templateID
        self.tipText = tipText
        self.category = category
    }
}

/// The rendered output of a streak-rescue nudge selection. The host app
/// presents this as a notification or in-app banner.
///
/// Conforms to `Identifiable` via a per-instance UUID for sheet/item
/// SwiftUI presentations. See ``FramingResult`` for the rationale.
public struct NudgeResult: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let templateID: String
    public let title: String
    public let body: String
    /// Suggested quick-start session length copy, e.g. "Try a 10-minute
    /// session". Length adapts to the user's recent average — short sessions
    /// for users who run short, longer for users who run longer.
    public let quickStartSuggestion: String

    public init(
        id: UUID = UUID(),
        templateID: String,
        title: String,
        body: String,
        quickStartSuggestion: String
    ) {
        self.id = id
        self.templateID = templateID
        self.title = title
        self.body = body
        self.quickStartSuggestion = quickStartSuggestion
    }
}
