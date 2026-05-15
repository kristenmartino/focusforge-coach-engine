import Foundation

/// How a focus session ended. The host app supplies this when asking for a
/// post-session reflection. The package itself doesn't currently route on
/// outcome (the reflection branch keys on session length, not outcome), but
/// it's part of the public signature for future expansion and to make
/// callsites self-documenting.
public enum SessionOutcome: String, Codable, Sendable {
    case completed
    case abandoned
}
