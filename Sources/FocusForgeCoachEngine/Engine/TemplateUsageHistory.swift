import Foundation

/// Categorizes a template by which engine entry point produced it. Used by
/// ``TemplateUsageHistory`` so deduplication can be scoped per feature
/// (framing dedup shouldn't suppress reflection templates and vice versa).
public enum AIFeatureType: String, Codable, Sendable {
    case framing
    case reflection
    case nudge
}

/// Source of recently-shown template IDs. The engine reads this to avoid
/// showing the same template twice in a row.
///
/// Implementations can back this with anything — SwiftData, Core Data, a
/// plain `UserDefaults` array, an in-memory set. The package ships an
/// ``InMemoryTemplateHistory`` you can use for previews, tests, or if you
/// don't care about persistence across launches.
///
/// **Convention:** `recentTemplateIDs(featureType:limit:)` returns the most
/// recently shown template IDs for the given feature, up to `limit`. The
/// engine treats these as ineligible when picking the next template. After
/// the engine returns a result, the host app should call
/// ``recordShown(templateID:featureType:)`` to update history.
public protocol TemplateUsageHistory: AnyObject {

    /// The most recently shown template IDs for this feature type.
    /// Order from most-recent to oldest is not required — the engine only
    /// uses these as a deduplication set.
    func recentTemplateIDs(featureType: AIFeatureType, limit: Int) -> Set<String>

    /// Called after the engine selects a template. Implementations should
    /// persist this so future calls to ``recentTemplateIDs(featureType:limit:)``
    /// include it.
    func recordShown(templateID: String, featureType: AIFeatureType)
}

/// In-memory ``TemplateUsageHistory`` for tests, previews, or applications
/// that don't care about cross-launch deduplication.
///
/// Stores up to 50 entries per feature in a FIFO queue. Not thread-safe;
/// suitable for use from the main actor.
public final class InMemoryTemplateHistory: TemplateUsageHistory {
    private var entries: [AIFeatureType: [String]] = [:]
    private let maxEntries: Int

    public init(maxEntries: Int = 50) {
        self.maxEntries = maxEntries
    }

    public func recentTemplateIDs(featureType: AIFeatureType, limit: Int) -> Set<String> {
        let all = entries[featureType] ?? []
        return Set(all.prefix(limit))
    }

    public func recordShown(templateID: String, featureType: AIFeatureType) {
        var list = entries[featureType] ?? []
        list.insert(templateID, at: 0)
        if list.count > maxEntries {
            list = Array(list.prefix(maxEntries))
        }
        entries[featureType] = list
    }

    /// Resets stored history. Useful between tests.
    public func reset() {
        entries.removeAll()
    }
}
