# FocusForgeCoachEngine

> A deliberately-not-an-LLM coaching engine for focus-session apps.
> The behavior layer that powers the AI Coach in
> [FocusForge](https://github.com/kristenmartino/focusforge).

[![Swift 5.9+](https://img.shields.io/badge/swift-5.9%2B-orange.svg)]()
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)]()
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## What this is

A small Swift package that turns the user's current behavior (completion rate,
abandon rate, streak risk, session length) into one of three coaching
moments — **intent framing** before a session, **reflection** after, and a
**streak rescue nudge** when the streak is at risk.

It does this **without an LLM**. There is no cloud call, no model
inference, no behavioral data leaving the device. The "AI" is a
hand-authored catalog of ~33 templates plus a router that picks the right
one given the user's signal and preferred tone.

## Why no LLM?

Three reasons, in order of how much they matter to me:

1. **Privacy as a structural claim.** "Your focus data never leaves your
   phone" is only credible if there's nothing on the other side of a
   network call to send it to. A locally-bundled template catalog makes
   that claim provable — you can read the entire decision surface in
   [`CoachTemplateCatalog.swift`](Sources/FocusForgeCoachEngine/Catalog/CoachTemplateCatalog.swift).

2. **Latency and reliability.** Coach messages render in a few
   milliseconds, even with the device offline. There is no spinner, no
   "AI is thinking…" state, no rate limit, no cost-per-user that scales
   with engagement.

3. **The job is small.** Routing a user from "high abandon rate + writing
   task" to "Just get words down. Aim for one paragraph to start" is
   pattern-matching, not generation. Spending a billion-parameter model
   on it is using a load-bearing wall for a coat hook.

This is not a take against LLMs in general — it's a take against using
them as a default. If you're tempted to reach for an LLM, you should
first ask: would a lookup table work? Often the answer is yes, and the
lookup table is more inspectable, faster, and safer.

## What it does

```swift
import FocusForgeCoachEngine

let history = InMemoryTemplateHistory()
let signal = BehaviorSignal(
    completionRate7d: 0.45,
    abandonRate7d: 0.35,
    avgActualFocusMinutes: 18,
    streakRiskScore: 0.2,
    totalSessions7d: 8
)

// Before a session starts:
let framing = CoachTemplateEngine.selectFramingTemplate(
    taskName: "Draft Q3 marketing report",
    signal: signal,
    tone: .encouraging,
    history: history
)
print(framing.reframedTask)
// → "Just get words down for Draft Q3 marketing report. Aim for one paragraph to start."
print(framing.motivationalLine)
// → "A rough draft is better than a blank page!"
history.recordShown(templateID: framing.templateID, featureType: .framing)

// After it ends:
let reflection = CoachTemplateEngine.selectReflectionTemplate(
    outcome: .completed,
    actualMinutes: 22,
    plannedMinutes: 25,
    signal: signal,
    tone: .encouraging,
    history: history
)
print(reflection.tipText)
// → "You stuck with it this time! That's a real win worth celebrating."

// When the streak is at risk:
let nudge = CoachTemplateEngine.selectNudgeTemplate(
    streakDays: 5,
    signal: signal,
    tone: .calm
)
print(nudge.title, nudge.body)
// → "Your streak matters" "Your 5-day streak is waiting for you. A brief session is all it takes."
print(nudge.quickStartSuggestion)
// → "Try a 15-minute session"
```

## How selection works

For framing, the engine:

1. Tokenizes the task name and looks each word up against
   [`keywordCategories`](Sources/FocusForgeCoachEngine/Catalog/CoachTemplateCatalog.swift)
   to bucket the task into one of: `study`, `writing`, `coding`,
   `creative`, `chores`, or `general`.
2. Derives a condition from the behavior signal — `newUser`,
   `highAbandon`, `lowCompletion`, `highCompletion`, or `default`.
3. Filters the catalog for templates matching `(category, condition)`,
   excluding any IDs the supplied `TemplateUsageHistory` says were
   shown recently (default: last 3).
4. Picks one at random, falling back to same-category-any-condition,
   then to general+default, then to the first template in the catalog.
5. Interpolates the user's task name, runs the output through a
   safety filter (catches shaming language, caps length at 300 chars),
   and returns a `FramingResult`.

Reflection follows the same pattern; nudges route on streak length
(`1...3`, `4...7`, `8...14`, `15...999`) and don't consult history
(they're cooldown-throttled by the host app).

For a complete trace, read the
[implementation](Sources/FocusForgeCoachEngine/Engine/CoachTemplateEngine.swift) —
the whole engine is one ~250-line file.

## Architecture choices worth calling out

**No SwiftData, no Core Data, no persistence at all.** The package
defines a `TemplateUsageHistory` protocol for "what did the user see
recently" so consumers can plug in whatever storage they use. An
`InMemoryTemplateHistory` ships with the package for previews and
tests.

**No `ModelContext`, no `@MainActor`, nothing platform-bound.** Pure
Swift. Works on iOS, macOS, watchOS, tvOS. The package depends only on
`Foundation`.

**Deterministic test variants.** Every selection method has a `using:
inout RNG` overload that takes an explicit random number generator. Tests
seed an LCG and assert exact template IDs come back. Production callers
use the default overload, which seeds from `SystemRandomNumberGenerator`.

**`Sendable` end to end.** All public types — including the engine
itself — are concurrency-safe. The engine is an `enum` of static methods,
so there's nothing to share.

**Safety filter as defense in depth.** The bundled catalog is
hand-reviewed and is not the threat model — the filter exists to protect
downstream consumers who extend the catalog. It catches shaming phrases
("you failed", "lazy", "pathetic", etc.) and enforces a 300-character
cap on rendered output.

## Customizing the catalog

Three options, in order of increasing commitment:

**1. Use the bundled catalog as-is.** It's tuned for a Pomodoro app but
the conditions are general enough to work for any session-based focus
tool.

**2. Pass your own array of templates.** Every selector takes a
`catalog:` parameter that defaults to the bundled catalog. Drop in your
own:

```swift
let custom: [FramingTemplate] = […]
let framing = CoachTemplateEngine.selectFramingTemplate(
    taskName: task,
    signal: signal,
    tone: tone,
    history: history,
    catalog: custom
)
```

**3. Fork the package.** The catalog file is plain Swift; adding
templates, categories, or conditions is mechanical.

## Installation

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kristenmartino/focusforge-coach-engine", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["FocusForgeCoachEngine"])
]
```

Or in Xcode: **File → Add Package Dependencies →**
`https://github.com/kristenmartino/focusforge-coach-engine`.

## Tests

```bash
swift test
```

66 tests covering the catalog, the engine's selection algorithm, the
safety filter, the in-memory history, and the behavior signal math.

## Status

`1.0.0` is what powers the AI Coach in FocusForge v1.0 (currently in
TestFlight). The API is stable; breaking changes will follow semver.

## License

MIT. See [LICENSE](LICENSE).

---

Built solo by [Kristen Martino](https://github.com/kristenmartino) for
[FocusForge](https://github.com/kristenmartino/focusforge).
