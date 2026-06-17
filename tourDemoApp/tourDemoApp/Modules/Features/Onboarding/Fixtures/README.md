# Onboarding fixture audio

The recording screen (`VoiceRecordingView` → `FixtureAudioTranscriber`) plays a
bundled clip in the **Simulator / demo video** while it streams the matching
captions. On a **real iOS 26 device** the live mic is used instead (play the clip
aloud from your computer so the device hears it).

## Add your clip

Drop the audio file into the app target named:

```
onboarding_preferences.m4a
```

(Any location inside the `tourDemoApp/` app folder works — the synchronized Xcode
group bundles it as a resource. Keep this `Fixtures/` folder if you like.)

- The clip should say roughly the canonical script in
  `Modules/Services/Extraction/OnboardingFixtures.swift` so the streamed captions
  line up. If your audio says something different, update that `transcript` (and,
  if the preferences differ, the `draft` cards) to match.
- Want a different filename/format? Pass `audioResource:` / `audioExtension:` to
  `FixtureAudioTranscriber` (see `OnboardingVoiceFactory`).
- **If no clip is present, the flow still works** — the captions stream silently.

Supported formats: anything `AVAudioPlayer` reads (`.m4a`, `.caf`, `.wav`, `.mp3`).
