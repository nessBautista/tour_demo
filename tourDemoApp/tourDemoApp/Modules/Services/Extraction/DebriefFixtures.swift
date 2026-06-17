//
//  DebriefFixtures.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  Canned debrief drafts, ported from the MVP's voice-test-scripts. Picked by the
//  home being debriefed so the demo is deterministic and the re-rank is visible:
//
//   • "alder" (the current front-runner) → the D1 "yard is too much" second look:
//     the buyer who made a big yard a must-have now wants LESS of it. That flips a
//     high-weight dimension and drops every yard-heavy home — the clearest possible
//     demonstration that a spoken impression rewrote the ranking.
//   • anything else → a warm impression with a couple of per-home perceptions and
//     no profile change (restraint — not every debrief should rewrite memory).
//

import Foundation
import ComparisonCore

struct DebriefFixture: Sendable {
    let transcript: String
    let draft: DebriefDraft
}

enum DebriefFixtures {
    /// D1 — "The yard is too much" (a contradiction of the onboarding must-have).
    static let yardTooMuch = DebriefFixture(
        transcript: """
        We went back for a second look, and honestly the yard is starting to scare me. \
        It's beautiful, but it's huge — every-weekend-mowing huge, and those garden beds \
        are way beyond me. I said a yard was non-negotiable, but what I actually want is \
        something low-maintenance. The light is still gorgeous though, and the street is so quiet.
        """,
        draft: DebriefDraft(
            positives: ["The afternoon light still glows", "The street is genuinely quiet"],
            concerns: ["The yard is more upkeep than we want"],
            openQuestions: [],
            preferenceUpdates: [
                PreferenceProposal(
                    kind: .priority,
                    title: "Less yard to keep up",
                    quote: "what I actually want is something low-maintenance",
                    dimension: .yard, direction: .wantsLess, importance: .high),
            ],
            perceptions: [
                HomePerception(dimension: .yard, polarity: .worse,
                               reason: "Every-weekend mowing; the beds are beyond us"),
                HomePerception(dimension: .light, polarity: .better,
                               reason: "The whole back of the house glows in the afternoon"),
            ],
            summary: "Second look — the yard now feels like too much to keep up."
        )
    )

    /// Default: a positive impression that nudges this home without touching the
    /// global profile (positives raise its perceived ratings a little).
    static let warmImpression = DebriefFixture(
        transcript: """
        Really liked this one. The kitchen is honestly great — well laid out, room to \
        actually cook — and the parking out front is a relief. I do want to ask the agent \
        how old the roof is, the shingles looked a little tired.
        """,
        draft: DebriefDraft(
            positives: ["The kitchen is well laid out", "Easy parking out front"],
            concerns: [],
            openQuestions: ["How old is the roof?"],
            preferenceUpdates: [],
            perceptions: [
                HomePerception(dimension: .kitchen, polarity: .better,
                               reason: "Well laid out, room to actually cook"),
                HomePerception(dimension: .parking, polarity: .better,
                               reason: "Easy parking right out front"),
            ],
            summary: "Liked it — strong kitchen and easy parking; roof age to check."
        )
    )

    /// The fixture for a given home: the yard contradiction for the yard-heavy
    /// front-runner (Alder), a warm impression otherwise.
    static func fixture(for home: Home) -> DebriefFixture {
        home.address.localizedCaseInsensitiveContains("alder") ? yardTooMuch : warmImpression
    }
}
