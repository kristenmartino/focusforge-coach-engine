import Foundation

/// Filters template output for shaming language and length.
///
/// The coach catalog is hand-written and reviewed, so the safety filter is
/// primarily a defense in depth — useful when downstream consumers extend
/// the catalog with their own templates and might accidentally introduce
/// hostile copy.
///
/// **Banned patterns** (case-insensitive substring match): "you failed",
/// "you should be ashamed", "disappointed in you", "lazy", "pathetic",
/// "useless", "waste of time", "giving up", "loser", "shame on",
/// "what's wrong with you", "can't even", "you never", "you always fail".
/// Any match replaces the entire output with a benign fallback string.
///
/// **Length cap:** outputs longer than 300 characters are truncated to 297
/// with a `…` appended. This protects against accidental long-form copy
/// breaking notification or banner layouts.
public enum SafetyFilter {

    /// Banned substring patterns. Case-insensitive. If any pattern matches,
    /// ``apply(_:)`` returns ``fallbackMessage``.
    public static let bannedPatterns: [String] = [
        "you failed", "you should be ashamed", "disappointed in you",
        "lazy", "pathetic", "useless", "waste of time", "giving up",
        "loser", "shame on", "what's wrong with you", "can't even",
        "you never", "you always fail",
    ]

    /// Returned in place of any text that hits a banned pattern.
    public static let fallbackMessage = "Great job focusing today. Keep it up!"

    /// Maximum allowed output length, in characters. Texts longer than this
    /// are truncated to `maxLength - 3` and suffixed with `...`.
    public static let maxLength = 300

    /// Runs the filter. Returns the original string if it's safe; the
    /// fallback message if it hits a banned pattern; or a truncated copy
    /// if it exceeds the length cap.
    public static func apply(_ text: String) -> String {
        let lowered = text.lowercased()
        for pattern in bannedPatterns {
            if lowered.contains(pattern) {
                return fallbackMessage
            }
        }

        if text.count > maxLength {
            return String(text.prefix(maxLength - 3)) + "..."
        }

        return text
    }
}
