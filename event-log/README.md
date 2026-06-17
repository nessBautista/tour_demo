# EventLog

The telemetry backbone for the Tour Debrief Companion demo — one event system
the whole app **and** the agent harness emit into, so every user action and
every model call is traceable. Built for product iteration: you can see what
happened, correlate a whole flow, and add up the **cost of inference**.

This is **PR 4 (`feat/logging`)** from the build order in
[`docs/SOLUTION.md`](../docs/SOLUTION.md) (the agent harness is "observable —
each step emits an event"). Pure Foundation: builds and tests anywhere.

## Why it exists

Lane-1's whole point is to *measure* the process so we know what's worth
automating. This package is where that measurement lands:

- **Traceability** — every step (voice → extraction → confirmation → ranking →
  next action) emits an event, correlated by a `traceID`, so a whole trajectory
  is reconstructable.
- **Cost of inference** — model calls record tokens + latency as structured
  `InferenceMetrics`; a `PricingBook` turns those into dollars on demand. Even if
  the agent runs on-device (free), you get an *estimate* of cloud cost.
- **Funnel** — product events (`debrief.recorded`, `preference.accepted`, …)
  feed the in-app event log and the funnel the experiment is judged on.

## Design

```
EventLogger              ← the app/agent emit through this (log / inference)
   └─ EventSink (protocol)        ← the swappable destination seam
        ├─ InMemoryEventSink      (in-app log, cost rollups, tests; thread-safe)
        ├─ ConsoleEventSink       (dev)
        ├─ MultiplexEventSink     (fan-out: memory + console + …)
        └─ NoOpEventSink          (disabled)
Models:    Event · EventCategory · InferenceMetrics
Pricing:   ModelPricing · PricingBook (.anthropicJune2026)
Reporting: events.inferenceSummary(pricing:)  → calls · tokens · $ · unpriced
Factory:   LoggingFactory.make() → (logger, store)
```

- **`Event`** — id · timestamp · name · category · properties · `traceID` · optional `InferenceMetrics`. `Codable`, so it can later ship to the backend `events` table without a DTO.
- **`EventSink`** — synchronous, `Sendable` `record(_:)`; callable from anywhere (main actor, background, agent loop) without `await`. Implementations own thread-safety (`InMemoryEventSink` uses a lock).
- **`PricingBook`** — cost is *derived* from recorded metrics, never stored, so a price change doesn't rewrite history. An unpriced model yields `nil` cost (surfaced, not silently zero).
- **`LoggingFactory.make()`** — the package owns the wiring: always in-memory, plus console in DEBUG.

## Usage

```swift
import EventLog

let logging = LoggingFactory.make()   // build once, at launch
let logger = logging.logger
let store = logging.store

// product / funnel events
logger.log("debrief.recorded", properties: ["home": homeID], traceID: runID)
logger.log("preference.accepted", properties: ["dimension": "yard"], traceID: runID)

// a model call — traceable + costable
logger.inference(
    model: "claude-opus-4-8", operation: "extraction",
    inputTokens: 1_240, outputTokens: 310, cacheReadTokens: 0,
    latencyMS: 840, traceID: runID
)

// later: what did inference cost?
let summary = store.events.inferenceSummary(pricing: .anthropicJune2026)
print(summary.calls, summary.totalTokens, summary.totalCostUSD, summary.unpricedModels)
```

## Build · test

```bash
swift build
swift test     # models, sinks (incl. a concurrency stress test), pricing, summary
```

All tests are pure and offline. The pricing fixtures are hand-computed
(e.g. 1M input + 1M output on Opus 4.8 = $30).

## Notes

- **Pricing is a dated snapshot** (`anthropicJune2026`, USD/MTok, cache-read ≈ 0.1× input). Update when prices change — it's data, not logic.
- **Remote sink is a follow-up.** A `SupabaseEventSink` that writes to the backend `events` table slots in behind `EventSink` with no caller change — the backend already has that table in its schema plan.
- The app would typically build the logging setup **once** at launch (`LoggingFactory.make()`) and inject the `logger` everywhere, holding the `store` where the developer view / cost panel reads it.
