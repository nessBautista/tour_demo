//
//  FixtureDebriefEngine.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The keyless/demo debrief engine: returns the canned draft for the home being
//  debriefed (the transcript is ignored — the fixture is the point). Mirrors
//  FixtureOnboardingEngine, including the fake latency so the extracting screen's
//  tool-call animation plays through. The agent loop replaces this in Phase 3.
//

import Foundation

struct FixtureDebriefEngine: DebriefExtracting {
    /// Fake latency; long enough for the extracting screen's reveal to play.
    /// Set to `.zero` in tests for instant, deterministic runs.
    var simulatedDelay: Duration = .milliseconds(2200)

    func extract(transcript: String, home: Home) async throws -> DebriefDraft {
        if simulatedDelay > .zero {
            try await Task.sleep(for: simulatedDelay)
        }
        return DebriefFixtures.fixture(for: home).draft
    }
}
