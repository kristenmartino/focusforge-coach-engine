# FocusForgeCoachEngine

A Swift package for adaptive, template-based focus coaching. It selects short
prompts from a bundled catalog using task keywords, recent session behavior,
streak length, and a preferred tone. It runs locally and makes no model or
network calls.

Used by [FocusForge](https://github.com/kristenmartino/focusforge), where the
feature is labeled “AI Coach.” This package implements rule-based template
selection. The catalog is fixed and inspectable.

## What it does

- **Before a session:** selects an intent-framing prompt by task category and
  behavior condition.
- **After a session:** selects a reflection based on session length and recent
  completion behavior. The current algorithm does not use the supplied outcome
  or planned duration.
- **At streak risk:** selects a nudge by streak-length range. The host app handles
  cooldowns.

The bundled catalog has 14 framing, 10 reflection, and 8 nudge templates with
three tone variants. Selection can vary among eligible templates. Supplying a
seeded random-number generator makes that choice reproducible in tests.

## Example

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

let framing = CoachTemplateEngine.selectFramingTemplate(
    taskName: "Draft Q3 marketing report",
    signal: signal,
    tone: .encouraging,
    history: history
)
print(framing.reframedTask)
```

## Selection and fallback behavior

For framing, the engine categorizes task keywords, derives a behavior condition,
and filters matching templates while excluding recently used IDs. It randomly
selects an eligible template, then falls back to the same category, general
defaults, or the first catalog entry. Custom catalogs must be non-empty.

It interpolates the task name and applies a short text filter. The filter caps
length and rejects listed shaming patterns; it is not a comprehensive safety
classifier. Inspect [`CoachTemplateEngine.swift`](Sources/FocusForgeCoachEngine/Engine/CoachTemplateEngine.swift),
[`CoachTemplateCatalog.swift`](Sources/FocusForgeCoachEngine/Catalog/CoachTemplateCatalog.swift),
and [`SafetyFilter.swift`](Sources/FocusForgeCoachEngine/Engine/SafetyFilter.swift)
for the rules.

## Integration and limits

The package uses Foundation and has no persistence or network client.
`TemplateUsageHistory` lets the host app provide storage; `InMemoryTemplateHistory`
is supplied for simple integrations and tests. This local processing statement
applies to the package, not to the host app's analytics or other services.

Templates provide bounded, predictable prompts. They do not answer arbitrary
questions or generate new advice.

Consumers can use the bundled catalog, pass custom template arrays through the
`catalog:` parameters, and supply a `RandomNumberGenerator` through the `using:`
overloads for reproducible selection.

## Install

Add the package through Xcode's **File → Add Package Dependencies** using:

```text
https://github.com/kristenmartino/focusforge-coach-engine
```

## Verify

```bash
swift test
```

Tests cover catalog structure, selection and fallbacks, filtering, template
history, and behavior-signal calculations. A passing suite checks these behaviors;
it does not validate coaching outcomes.

## License

MIT. See [LICENSE](LICENSE).
