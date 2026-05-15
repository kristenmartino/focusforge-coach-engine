# FocusForgeCoachEngine

> A hand-written focus coach.
> The behavior layer that powers the AI Coach in
> [FocusForge](https://github.com/kristenmartino/focusforge).

[![Swift 5.9+](https://img.shields.io/badge/swift-5.9%2B-orange.svg)]()
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)]()
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## What this is

A small Swift package that turns the user's current behavior (completion
rate, abandon rate, streak risk, session length) into one of three
coaching moments — **intent framing** before a session, **reflection**
after, and a **streak rescue nudge** when the streak is at risk.

The whole engine fits in ~250 lines of routing logic and a catalog of
**33 hand-written templates** — 15 framings, 10 reflections, 8 nudges,
each authored in three tones (encouraging, direct, calm). That's roughly
**99 distinct pieces of micro-copy**, all written by one person, none
generated.

You can read the entire decision surface of the coach in a single file:
[`CoachTemplateCatalog.swift`](Sources/FocusForgeCoachEngine/Catalog/CoachTemplateCatalog.swift).

That's the point.

## Why hand-written

Most "AI coaching" today is a wrapper around a frontier model, and the
output reads like it. `"You're doing great! Keep up the awesome work! 🌟
Remember, every step counts on your journey to success! 💪"` — the
voice of nobody, for nobody, polished to a sheen that has no taste.

FocusForge's coach is the opposite bet:

- **Every line is writing, not output.** A writer chose each word.
  Tone variants exist because a person's preference for "Take a breath
  and begin" over "Start strong." is a real preference, not a parameter
  to tune. The encouraging variant exclaims. The direct variant
  commands. The calm variant invites. You can tell which is which
  without being told.

- **Variety comes from authoring, not sampling.** The catalog
  deduplicates against recent history so the user doesn't see the same
  template twice in a row, but the variety is bounded by the writer.
  No template ever gets accidentally aggressive or syrupy because
  someone tweaked the temperature.

- **The safety floor is read, not promised.** Below the catalog, a
  10-line filter rejects shaming patterns — "you failed," "lazy,"
  "pathetic," etc. — and caps output at 300 characters. You can read
  the list in [`SafetyFilter.swift`](Sources/FocusForgeCoachEngine/Engine/SafetyFilter.swift).
  It's auditable. It's not "the model has been aligned."

The trade is real: the coach can't say genuinely new things. It can't
adapt to a user typing "help me focus on debugging segfaults in this
specific kernel module." It picks one of 99 written pieces, fills in
the task name, and ships.

For a focus app, that trade is the *right way around*. A focus app
shouldn't be talking to the user during their focus block. It should
show up briefly with one well-chosen sentence and then get out of the
way. Picking from a tight catalog of human-written lines does that
better than a model that has to be wrangled into brevity.

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
```

## The craft, end-to-end

This package is one piece of a larger handmade thing. In FocusForge:

- The **timer ring** is three composed layers — subtle track, wide glow
  aura at 15% opacity, thin crisp ring at 90% — not a default
  `Circle().trim()`.
- The **reward moment** is a 5-beat cinematic animation. Ring pulse →
  background crossfade to deep purple → checkmark + headline →
  reward card with count-up XP → CTA fade-in. Each beat hand-tuned.
- The app has **two emotional registers**. Focus mode: near-black,
  one accent color, the character absent. Reward mode: deep purple
  atmosphere, layered radial glows, particles, dramatic character
  lighting. The contrast between restraint and richness IS the
  dopamine hit.
- Every color is a named token in `FFTheme`. No raw `Color.blue`. No
  guess-the-hex. Contrast pairs measured against WCAG AA.
- The character grows with the user — a dressing room of cosmetics
  unlocked at streak milestones, rendered with real lighting and a
  ground plane that catches a subtle underglow.

The coach engine is the writing layer of the same project. It sits
underneath three SwiftUI views in FocusForge — `IntentFramingView`,
`PostReflectionCardView`, `StreakRescueBannerView` — each composed
with the same atmospheric design system. The coach's words land on
surfaces that were drawn, not stamped out.

If you want to see what this looks like in motion, the app is
[here](https://github.com/kristenmartino/focusforge).

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
5. Interpolates the user's task name, runs the output through the
   safety filter, and returns a `FramingResult`.

Reflection follows the same shape; nudges route on streak length
(`1...3`, `4...7`, `8...14`, `15...999`) and don't consult history
(they're cooldown-throttled by the host app via `NudgeFrequency`).

The whole engine is one ~250-line file. Worth reading:
[`CoachTemplateEngine.swift`](Sources/FocusForgeCoachEngine/Engine/CoachTemplateEngine.swift).

## Architecture choices

**No SwiftData, no Core Data, no persistence at all.** The package
defines a `TemplateUsageHistory` protocol for "what did the user see
recently" so consumers can plug in whatever storage they use. An
`InMemoryTemplateHistory` ships with the package for previews and
tests.

**No `ModelContext`, no `@MainActor`, nothing platform-bound.** Pure
Swift. Works on iOS, macOS, watchOS, tvOS. Foundation only.

**Deterministic test variants.** Every selection method has an
`using: inout RNG` overload that takes an explicit random number
generator. Tests seed an LCG and assert exact template IDs come back.

**`Sendable` end to end.** All public types — including the engine
itself — are concurrency-safe.

**Nothing leaves the device.** The engine doesn't know what a
network is. The host app's behavior data — task names, completion
rates, streak history — is read locally and consumed locally. The
privacy claim isn't a policy; it's a property of the architecture.

## Customizing the catalog

Three options, in order of increasing commitment:

**1. Use the bundled catalog as-is.** It's tuned for a Pomodoro app
but the conditions are general enough to work for any session-based
focus tool.

**2. Pass your own array of templates.** Every selector takes a
`catalog:` parameter that defaults to the bundled catalog. Drop in
your own:

```swift
let myFramings: [FramingTemplate] = [
    FramingTemplate(
        id: "frm_custom_01",
        category: "general",
        condition: .default,
        reframeFormat: [
            .encouraging: "Today's focus: %@. What's the one thing?",
            .direct: "%@. Pick one outcome.",
            .calm: "Settle into %@. One small piece.",
        ],
        motivationalLine: [
            .encouraging: "You've got this.",
            .direct: "Go.",
            .calm: "Breathe.",
        ]
    ),
    // ...
]

let framing = CoachTemplateEngine.selectFramingTemplate(
    taskName: task,
    signal: signal,
    tone: tone,
    history: history,
    catalog: myFramings
)
```

**3. Fork the package.** The catalog file is plain Swift; adding
templates, categories, or conditions is mechanical. If you write
copy you're proud of, send a PR — the bundled catalog is opinionated
but not territorial.

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
