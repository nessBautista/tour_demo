//
//  DebriefExtracting.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The debrief counterpart of OnboardingExtracting: a post-tour voice impression
//  → a structured draft the buyer confirms. A debrief produces TWO kinds of
//  scoring effect, kept distinct on purpose (§3, "comparison aid"):
//
//   • `preferenceUpdates` change the GLOBAL buyer profile — they re-rank every
//     home (e.g. "the yard is too much now" → wants less yard everywhere).
//   • `perceptions` re-rate only THIS home — a dimension nudged up/down because
//     of what the buyer saw in person.
//
//  Both only ever touch memory after the buyer confirms (the human-in-the-loop).
//  Fixture now; the agent ReAct loop (agent/react-loop) drops in behind this seam.
//

import Foundation
import ComparisonCore

/// A dimension-tagged reaction to ONE home (not the global profile). The debrief
/// saw the trait in person and wants this home's perceived rating nudged.
struct HomePerception: Sendable, Equatable {
    /// `better` raises the home's match on the dimension; `worse` lowers it —
    /// regardless of the buyer's direction (see `BuyerMemoryStore.adjust`).
    enum Polarity: Sendable, Equatable { case better, worse }

    let dimension: HomeDimension
    let polarity: Polarity
    /// The buyer's own words — shown on the confirmation card.
    let reason: String
}

/// One debrief's structured output, before the buyer confirms. Positives/concerns/
/// questions are the human-facing impression; the two scoring lists drive the
/// re-rank. `preferenceUpdates` reuses `PreferenceProposal` so the confirmation
/// cards render identically to onboarding.
struct DebriefDraft: Sendable {
    var positives: [String] = []
    var concerns: [String] = []
    var openQuestions: [String] = []
    var preferenceUpdates: [PreferenceProposal] = []
    var perceptions: [HomePerception] = []
    var summary: String? = nil
}

/// Turns a debrief transcript (for a specific home) into a draft.
protocol DebriefExtracting: Sendable {
    func extract(transcript: String, home: Home) async throws -> DebriefDraft
}
