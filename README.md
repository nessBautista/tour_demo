# Tour Debrief Companion

**An AI-native iOS prototype for the moment right after a home tour** — it turns a
30-second voice reaction into memory, explainable comparison, and a confident next step.

> A solo, time-boxed prototype. Full write-up: [`docs/SOLUTION.md`](docs/SOLUTION.md).

## ▶ Watch the pitch (~3 min)

A short deck with the live app demo embedded.

https://github.com/user-attachments/assets/558a481f-2eaf-4644-896c-b0452ce847fa

<sub>Or run the deck interactively at [`presentation/index.html`](presentation/index.html). Source file: [`presentation/assets/pitch_v1.mp4`](presentation/assets/pitch_v1.mp4).</sub>


## The problem

A buyer tours **~8 homes** before they transact. The bottleneck isn't booking — it's
**cognition**: after a tour, impressions are unstructured and fade within days, so the
next decision stalls. That post-tour moment is the one funnel stage an AI-native product
can actually move.

## The solution — a post-tour loop

1. **Voice debrief** — a 20–30s reaction, transcribed on-device.
2. **Buyer memory** — extraction proposes preference updates; the buyer approves each one
   before anything is saved.
3. **Explainable compare** — toured homes re-rank against current memory, and the order is
   *explained*, not just listed.
4. **Next best action** — one grounded move.

**The bet:** the win isn't one more booking — it's a *better touring experience*. An
explainable rank helps the buyer organize what they actually want, so every tour becomes a
sharper decision.

## How it's built — two pillars

- **A deterministic comparison core.** `fit` is a pure, unit-tested, magnitude-weighted
  function — the model never computes the ranking.
- **A small, bounded ReAct agent** wrapped around it. It acts only through a fixed tool
  set, every change is human-confirmed, and it can *read* the score but never override it.

Deeper design + the build order are in [`docs/SOLUTION.md`](docs/SOLUTION.md).
