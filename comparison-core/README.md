# ComparisonCore

The deterministic ranking engine for the Tour Debrief Companion demo. Given a
buyer's preferences and a set of homes, it produces a **ranked, explainable
ordering** — the same inputs always yield the same order, and every number
traces back to a rating and a weight. No I/O, no randomness, no model in the loop.

This is **PR 2 (`feat/comparison-core`)**. It's a Swift package so the app can
`import ComparisonCore` later; for now a small CLI exercises it from a terminal.
See [`docs/SOLUTION.md`](../docs/SOLUTION.md) §3 for the full rationale.

## The math

Each home has a **rating** per dimension (0–100, higher = more of the trait:
more yard, shorter commute, quieter). Each buyer preference has a **direction**
(`wantsMore` / `wantsLess`) and an **importance** (low · medium · high → weight
1 · 2 · 3).

```
match = rating          if wantsMore
      = 100 - rating     if wantsLess        (per preference, 0–100)

fit%  = Σ(weight × match) / Σ(weight)        over the buyer's preferences
```

`match` turns "how much of a trait" into "how desirable to this buyer"; `fit` is
the importance-weighted average of those matches.

## Design

```
HomeRankingFactory.makeDefault(preferences:) → any HomeRanking   ← single construction point
HomeRanking (protocol)          ← depend on this; inject/swap implementations
   └─ FitScorer (struct)         init(preferences:) → score(_:) · rank(_:)
        ├─ Home         id, address, ratings: [HomeDimension: Int]
        ├─ Preference   dimension · direction · importance
        └─ FitScore     home · fit · breakdown: [DimensionMatch]   ← explains the number
```

- **`HomeRankingFactory`** — the construction seam. `makeDefault(preferences:)` returns `any HomeRanking` (today a `FitScorer`); `makeDemo()` wires the built-in sample profile. There's one strategy now, so it doesn't *select* like a platform factory — it's the single build point so a smarter or stubbed ranker can drop in later without touching callers.
- **`HomeRanking`** — the protocol the rest of the system depends on (`score`, `rank`). Callers hold an `any HomeRanking`, so the concrete engine can be swapped or stubbed. `rank` has a default implementation, so a conformer only needs `score`.
- **`FitScorer`** — the deterministic implementation, a `struct` (value semantics, `Sendable`, no shared state). Instantiated with a buyer's profile, then reused to `score(_:)` one home or `rank(_:)` many (best first; ties break by id). Immutable; `updating(preferences:)` makes a fresh one when the profile changes. `match(rating:direction:)` is a static helper.
- **`HomeDimension`** — the closed vocabulary (`yard commute quiet kitchen light parking budget note`). A fixed enum is what keeps the comparison deterministic and explainable.
- **`FitScore.breakdown`** — the per-preference contributions, so the ranking can be *shown*, not just asserted. This is what the app's Compare screen (and the agent's narration) read.
- **`DemoData`** — built-in homes + a sample profile so the CLI and tests need no backend.

The engine deliberately knows nothing about Supabase, voice, or UI — those wire
in around it later.

### Using it from another module

```swift
import ComparisonCore

// Depend on the protocol, construct the concrete engine.
let ranker: any HomeRanking = FitScorer(preferences: [
    Preference(dimension: .yard,  direction: .wantsMore, importance: .high),
    Preference(dimension: .quiet, direction: .wantsMore, importance: .medium),
])

let ranked = ranker.rank(homes)     // [FitScore], best fit first
for score in ranked {
    print(score.home.address, score.fit, score.breakdown)
}

// Buyer's preferences changed after a debrief? Make a new scorer:
let revised = FitScorer(preferences: newProfile)
```

## Build · run · test

Requires a Swift toolchain (Xcode 15+ / Swift 5.9+).

```bash
swift build
swift test          # unit tests pin the math (hand-computable fixtures)

swift run comparison-cli                       # rank demo homes, sample profile
swift run comparison-cli --prefer yard:less:high --prefer commute:more:high
```

`--prefer <dim>:<dir>:<imp>` is repeatable; `<dir>` is `more`/`less`, `<imp>` is
`low`/`med`/`high`. With no `--prefer` flags it uses the built-in sample profile.

### Example output

`swift run comparison-cli` (sample profile: wants yard (high) + quiet (med),
would take a shorter commute and a lower price (low)):

```
Ranked homes (best fit first):
  1. 77.1%   412 Alder Court, Maple Grove
  2. 71.4%   1735 Bellview Avenue, Old Town
  3. 30.0%   88 Foundry Lane #4B, Riverside District

Why 412 Alder Court, Maple Grove wins:
  yard      rating  90  (more) -> match  90 x weight 3 = 270
  quiet     rating  80  (more) -> match  80 x weight 2 = 160
  commute   rating  40  (more) -> match  40 x weight 1 =  40
  budget    rating  70  (more) -> match  70 x weight 1 =  70
  --------------------------------------------
  fit = 540 / 7 = 77.1%
```

Foundry tanks because it has no yard (rating 0 → match 0) and yard is the
highest-weighted preference — exactly the kind of trade-off the breakdown makes
legible.

## Notes

- Ratings here are illustrative; in the full app they come from voice extraction
  (a later PR). This package only does the math.
- A home that doesn't rate a preferred dimension counts as `0` for it (no
  evidence of the trait), and ratings are clamped to 0–100.
