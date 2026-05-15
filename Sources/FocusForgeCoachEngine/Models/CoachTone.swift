import Foundation

/// The voice the coach speaks in. Every template carries copy for all three
/// tones; the user picks their preference once and the engine reads the
/// matching variant when rendering.
///
/// The three tones map to roughly distinct emotional registers:
///
/// - ``encouraging`` — warm, optimistic, exclamation-friendly. The default.
///   "You've got this!"
/// - ``direct`` — short, imperative, no padding. For users who find cheerleading
///   distracting. "Start strong."
/// - ``calm`` — gentle, slower-paced, soft language. For anxious or burned-out
///   users. "Take a breath and begin."
///
/// Adding a tone requires writing copy for every existing template. Keep the
/// catalog small and the tone count finite.
public enum CoachTone: String, Codable, CaseIterable, Sendable {
    case encouraging
    case direct
    case calm
}
