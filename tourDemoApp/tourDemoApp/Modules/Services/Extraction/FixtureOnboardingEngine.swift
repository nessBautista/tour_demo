//
//  FixtureOnboardingEngine.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  Keyless, deterministic OnboardingExtracting conformer: returns the canonical
//  draft after a simulated "thinking" delay (so the recording → extracting screen
//  transition still feels real). The app's default until the live agent loop
//  (Phase 3) conforms to the same protocol.
//

import Foundation

struct FixtureOnboardingEngine: OnboardingExtracting {
    var fixture: OnboardingFixture = OnboardingFixtures.standard
    /// Fake latency; long enough that the extracting screen's tool-call animation
    /// plays through. Set to `.zero` in tests for instant, deterministic runs.
    var simulatedDelay: Duration = .milliseconds(2600)

    func extract(transcript: String) async throws -> OnboardingDraft {
        // Fixture path: the transcript is ignored — the canned draft is the point.
        if simulatedDelay > .zero {
            try await Task.sleep(for: simulatedDelay)
        }
        return fixture.draft
    }
}
