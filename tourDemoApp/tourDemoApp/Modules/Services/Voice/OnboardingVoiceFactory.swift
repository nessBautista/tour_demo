//
//  OnboardingVoiceFactory.swift
//  tourDemoApp — Modules/Services/Voice
//
//  Picks the transcriber for the recording screen. Mirrors the package's own
//  capability check, but swaps the Simulator/fallback path from the package's
//  text-only `StubTranscriber` to our `FixtureAudioTranscriber` (plays the fixture
//  clip + streams matching captions).
//
//  • Real iOS 26 device → SpeechTranscriptionService (real mic). On device we test
//    by playing the fixture audio aloud so the mic hears it.
//  • Simulator / everywhere else → FixtureAudioTranscriber (bundled clip + script).
//

import Foundation
import VoiceExtraction

enum OnboardingVoiceFactory {
    @MainActor
    static func make(script: String) -> any VoiceTranscribing {
        #if os(iOS) && !targetEnvironment(simulator)
        if #available(iOS 26, *) {
            return SpeechTranscriptionService()
        }
        #endif
        return FixtureAudioTranscriber(script: script)
    }
}
