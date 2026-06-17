//
//  OnboardingExtracting.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The onboarding extraction capability (Services tier). The ViewModel depends on
//  this protocol, never on a model/loop directly — so the fixture engine (now) and
//  the live agent loop (Phase 3: agent/react-loop) are swappable behind one seam.
//

import Foundation

/// The output of onboarding extraction: the buyer's initial preferences plus an
/// optional one-line summary, before the buyer confirms.
struct OnboardingDraft: Sendable {
    var preferences: [PreferenceProposal]
    var summary: String?

    init(preferences: [PreferenceProposal] = [], summary: String? = nil) {
        self.preferences = preferences
        self.summary = summary
    }

    var isEmpty: Bool { preferences.isEmpty && summary == nil }
}

/// Produces a preference draft from the buyer's onboarding voice memo.
protocol OnboardingExtracting: Sendable {
    func extract(transcript: String) async throws -> OnboardingDraft
}
