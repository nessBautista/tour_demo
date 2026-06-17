# VoiceExtraction

On-device voice → text for the Tour Debrief Companion demo. A buyer records a
short spoken impression after a tour; this package turns it into a transcript,
fully on device (audio never leaves the phone).

This is **PR 3 (`feat/voice-extraction`)**, promoted from the `voice-capture`
probe. It's a Swift package so the app can `import VoiceExtraction` later. See
[`docs/SOLUTION.md`](../docs/SOLUTION.md) §2 (step 2: voice debrief).

> Scope note: this PR is the **transcription** half ("voice → text"). Turning
> the transcript into structured, confirmable preference updates is the agent's
> job and lands in the agentic PRs — see Roadmap below.

## Platform reality

The engine is built on **`SpeechAnalyzer` / `SpeechTranscriber` (iOS 26+) and
`AVAudioSession`** — Apple frameworks that only do real work on a **recent
physical iPhone**. The Simulator ships no model assets (`supportedLocales` is
empty there), and these APIs don't exist on macOS/Linux.

So the package is split by what can run where:

| Part | Runs on | Notes |
|---|---|---|
| `LocaleResolver`, models, `StubTranscriber`, the protocol | anywhere (incl. macOS `swift test`) | pure / no hardware |
| `SpeechTranscriptionService`, `AudioCapture`, `SpeechPermissions` | iOS 26 device | `#if os(iOS)`-guarded so the package still builds on the macOS host |

## Design

```
VoiceTranscriberFactory.makeDefault() → any VoiceTranscribing   ← picks by platform
VoiceTranscribing (protocol)        ← depend on this; inject by environment
   ├─ SpeechTranscriptionService    (iOS 26, on device)   — the real engine
   └─ StubTranscriber               (anywhere)            — Simulator / previews / tests
Models:  ModelState · Transcript · PermissionStatus
Pure:    LocaleResolver            (desired locale → a supported one)
```

- **`VoiceTranscriberFactory`** — `makeDefault()` returns the real engine on an iOS 26 device and the stub everywhere else (Simulator, macOS, older iOS). The package owns this rule because it owns the availability knowledge; the app keeps override authority (force a stub for demos/previews/tests).
- **`VoiceTranscribing`** — the capability the app holds (same seam idea as `ComparisonCore`'s `HomeRanking`). Lifecycle: `prepare()` → `startRecording()` → observe `transcript` → `stopRecording()`.
- **`SpeechTranscriptionService`** — the real `SpeechAnalyzer`/`SpeechTranscriber` pipeline: model-asset check + download, mic capture, format conversion, volatile/final result handling, interruption safety. An `@Observable` model the SwiftUI view binds to (no Combine).
- **`StubTranscriber`** — a no-hardware stand-in that replays a canned transcript through the same lifecycle, so the UI builds and previews on the Simulator and the logic is unit-testable.
- **`Transcript`** — `volatile` (live, revisable) + `finalized` (confirmed, append-only); the split is what avoids duplicate-text bugs.
- **`LocaleResolver`** — resolves `Locale.current` against the transcriber's supported locales (exact → same-language → nil). Mandatory: a real device reported `en_MX`, which Apple ships no assets for, so it falls back to `en_US`.

## Build · test

Requires a Swift toolchain. On the macOS host, the pure parts build and test
(the iOS-only Apple code is excluded):

```bash
swift build
swift test        # LocaleResolver + StubTranscriber lifecycle
```

The transcription engine itself compiles and runs only in the **iOS app target
(iOS 26, physical device)** — there's no terminal harness for it (unlike
`comparison-cli`), because it needs a mic, permissions, and on-device models.

## Using it from the app

```swift
import VoiceExtraction

// Let the package pick: real engine on device, stub on Simulator/preview.
// Both implementations are @Observable, so this binds straight into a view.
@State private var transcriber = VoiceTranscriberFactory.makeDefault()

// 1. Permissions (once) — requires the two Info.plist usage strings.
let status = await SpeechPermissions.request()
guard status.allGranted else { /* show denied state */ return }

// 2. Prepare the model (resolves locale, downloads assets if needed).
await transcriber.prepare()

// 3. Record; bind transcriber.transcript.combined live in the UI.
await transcriber.startRecording()
// …user speaks…
await transcriber.stopRecording()
```

**Required Info.plist keys** (app target):

- `NSMicrophoneUsageDescription` — e.g. "Records your voice memo to transcribe it."
- `NSSpeechRecognitionUsageDescription` — e.g. "Transcribes your memo on this device."

## Roadmap / out of scope

- **Structured extraction** (transcript → confirmable preference/perception
  updates) is the agent's Extraction loop — a later PR. This package stops at
  the transcript.
- **Robustness cases** flagged in the probe still want device testing: 60 s+
  memos, permission denial states, mid-recording interruption. The handling is
  in place; the verification is device-only.

## Provenance

Promoted from `code/apps/tour_debrief/probes/voice-capture` (P2, core
transcription verified on a physical device 2026-06-10). The probe's research on
why `SpeechTranscriber` supersedes `SFSpeechRecognizer` (no 1-minute limit,
on-device-only) lives in that probe's README.
