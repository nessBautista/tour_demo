//
//  DebriefFixtures.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  Canned debrief drafts, keyed by the home being debriefed so the demo is
//  deterministic. Two effects are designed into the set:
//
//   • Alder's "yard is too much" (D1) flips a high-weight dimension and re-ranks
//     everything — the per-home-debrief payoff.
//   • EVERY home's draft mentions `light` (and most mention `quiet`/`kitchen`), so
//     after a few debriefs those dimensions recur — feeding the buyer-memory panel
//     its "mentioned at 3/3 homes → promote" recurrence signal. `light` starts
//     outside the profile, so promoting it visibly adds a new ranking dimension.
//

import Foundation
import ComparisonCore

struct DebriefFixture: Sendable {
    let transcript: String
    let draft: DebriefDraft
}

enum DebriefFixtures {
    /// Alder — the yard now feels like too much (a contradiction of the must-have);
    /// the light and the quiet still land.
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
            preferenceUpdates: [
                PreferenceProposal(
                    kind: .priority,
                    title: "Less yard to keep up",
                    quote: "what I actually want is something low-maintenance",
                    dimension: .yard, direction: .wantsLess, importance: .high),
            ],
            perceptions: [
                HomePerception(dimension: .yard,  polarity: .worse,
                               reason: "Every-weekend mowing; the beds are beyond us"),
                HomePerception(dimension: .light, polarity: .better,
                               reason: "The whole back of the house glows in the afternoon"),
                HomePerception(dimension: .quiet, polarity: .better,
                               reason: "Such a quiet street"),
            ],
            summary: "Second look — the yard now feels like too much to keep up."
        )
    )

    /// Foundry — a bright loft with a sharp kitchen, but right on a busy street.
    static let loftBright = DebriefFixture(
        transcript: """
        The loft is full of light — those big windows are everything, and the kitchen is \
        genuinely sharp, I could cook in there tomorrow. Only thing is it's right on a busy \
        street, you can hear the traffic with the windows open.
        """,
        draft: DebriefDraft(
            positives: ["Floods with light", "The kitchen is sharp"],
            concerns: ["Traffic noise off the street"],
            perceptions: [
                HomePerception(dimension: .light,   polarity: .better,
                               reason: "Huge windows — it's full of light"),
                HomePerception(dimension: .kitchen, polarity: .better,
                               reason: "Sharp kitchen, ready to cook in"),
                HomePerception(dimension: .quiet,   polarity: .worse,
                               reason: "Right on a busy street"),
            ],
            summary: "Bright loft with a great kitchen, but noisy off the street."
        )
    )

    /// Bellview — full of character on a quiet block, but dark and the kitchen needs a gut.
    static let craftsmanDim = DebriefFixture(
        transcript: """
        So much character in this one, and the block is lovely and quiet. But it's dark — \
        even mid-afternoon the rooms feel dim — and the kitchen really needs a full gut, \
        it's basically original.
        """,
        draft: DebriefDraft(
            positives: ["So much character", "A quiet block"],
            concerns: ["The rooms feel dark", "The kitchen needs a full gut"],
            perceptions: [
                HomePerception(dimension: .light,   polarity: .worse,
                               reason: "Even mid-afternoon the rooms feel dim"),
                HomePerception(dimension: .quiet,   polarity: .better,
                               reason: "Lovely quiet block"),
                HomePerception(dimension: .kitchen, polarity: .worse,
                               reason: "Original kitchen — needs a full gut"),
            ],
            summary: "Loads of character on a quiet block, but dark and the kitchen needs work."
        )
    )

    /// Default for any other home: a warm impression that still notes the light.
    static let warmImpression = DebriefFixture(
        transcript: """
        Really liked this one. Good light through the day, and the parking out front is a \
        relief. I do want to ask the agent how old the roof is — the shingles looked a bit tired.
        """,
        draft: DebriefDraft(
            positives: ["Good light through the day", "Easy parking out front"],
            openQuestions: ["How old is the roof?"],
            perceptions: [
                HomePerception(dimension: .light,   polarity: .better,
                               reason: "Good light through the day"),
                HomePerception(dimension: .parking, polarity: .better,
                               reason: "Easy parking right out front"),
            ],
            summary: "Liked it — good light and easy parking; roof age to check."
        )
    )

    /// The fixture for a given home, by address keyword.
    static func fixture(for home: Home) -> DebriefFixture {
        let address = home.address.lowercased()
        if address.contains("alder")    { return yardTooMuch }
        if address.contains("foundry")  { return loftBright }
        if address.contains("bellview") { return craftsmanDim }
        return warmImpression
    }
}
