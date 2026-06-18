//
//  DebriefFixtures.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  One debrief per house on the list, keyed by address. Each fixture carries:
//   • `transcript` — what the Simulator's FixtureAudioTranscriber streams, and the
//     fallback if live capture comes back empty (so the live agent extracts from it);
//   • `audioResource` — the bundled clip to play per house (drop `<name>.m4a` in the
//     app target; on a real device, play it aloud for the mic). Absent clip → the
//     captions still stream silently, so the flow always completes;
//   • `draft` — the canned result the FIXTURE engine returns when there's no API key.
//
//  The set is designed so the demo stays rich: Alder carries the contradiction
//  (yard must-have → wants-less), and `light` recurs across houses so the buyer-
//  memory panel's "mentioned at N/N homes → promote" surfaces.
//

import Foundation
import ComparisonCore

struct DebriefFixture: Sendable {
    let transcript: String
    let audioResource: String
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
        audioResource: "debrief_alder",
        draft: DebriefDraft(
            positives: ["The afternoon light still glows", "The street is genuinely quiet"],
            concerns: ["The yard is more upkeep than we want"],
            preferenceUpdates: [
                PreferenceProposal(
                    kind: .priority, title: "Less yard to keep up",
                    quote: "what I actually want is something low-maintenance",
                    dimension: .yard, direction: .wantsLess, importance: .high),
            ],
            perceptions: [
                HomePerception(dimension: .yard,  polarity: .worse,  reason: "Every-weekend mowing; the beds are beyond us"),
                HomePerception(dimension: .light, polarity: .better, reason: "The whole back of the house glows in the afternoon"),
                HomePerception(dimension: .quiet, polarity: .better, reason: "Such a quiet street"),
            ],
            summary: "Second look — the yard now feels like too much to keep up."
        )
    )

    /// Foundry — a bright loft with a sharp kitchen, but right on a busy street.
    static let loftBright = DebriefFixture(
        transcript: """
        The loft is full of light — those big windows are everything, and the kitchen is \
        genuinely sharp, I could cook in there tomorrow. The catch is it's right on a busy \
        street; with the windows open you really hear the traffic. I'd want to know whether \
        that can be dealt with before I get my hopes up.
        """,
        audioResource: "debrief_foundry",
        draft: DebriefDraft(
            positives: ["Floods with light", "The kitchen is sharp"],
            concerns: ["Traffic noise off the street"],
            openQuestions: ["Can the street-side windows be soundproofed?"],
            perceptions: [
                HomePerception(dimension: .light,   polarity: .better, reason: "Huge windows — it's full of light"),
                HomePerception(dimension: .kitchen, polarity: .better, reason: "Sharp kitchen, ready to cook in"),
                HomePerception(dimension: .quiet,   polarity: .worse,  reason: "Right on a busy street, you hear the traffic"),
            ],
            summary: "Bright loft with a great kitchen, but noisy off the street."
        )
    )

    /// Bellview — full of character on a quiet block, but dark and the kitchen needs a gut.
    static let craftsmanDim = DebriefFixture(
        transcript: """
        So much character in this one — original mouldings, the whole feel of it — and the \
        block is lovely and quiet. But it's dark; even mid-afternoon the rooms feel dim. And \
        the kitchen really needs a full gut, it's basically untouched since the seventies. \
        I'd need a real number on what that reno would cost.
        """,
        audioResource: "debrief_bellview",
        draft: DebriefDraft(
            positives: ["So much character", "A quiet block"],
            concerns: ["The rooms feel dark", "The kitchen needs a full gut"],
            openQuestions: ["What would a full kitchen reno cost here?"],
            perceptions: [
                HomePerception(dimension: .quiet,   polarity: .better, reason: "Lovely quiet block"),
                HomePerception(dimension: .light,   polarity: .worse,  reason: "Even mid-afternoon the rooms feel dim"),
                HomePerception(dimension: .kitchen, polarity: .worse,  reason: "Untouched since the seventies — needs a full gut"),
            ],
            summary: "Loads of character on a quiet block, but dark and the kitchen needs work."
        )
    )

    /// Oak — a pleasant surprise: smaller than it looked, but bright, walkable, easy parking.
    static let oakSurprise = DebriefFixture(
        transcript: """
        Honestly, Oak Street surprised me. It's smaller than the photos made it look, but \
        it's full of light all afternoon, and the block is so walkable — cafes, the park, all \
        right there. Parking out front was easy too. My only hesitation is whether that second \
        bedroom is really big enough for us.
        """,
        audioResource: "debrief_oak",
        draft: DebriefDraft(
            positives: ["Full of light all afternoon", "A walkable block — cafes and the park", "Easy parking out front"],
            concerns: ["The second bedroom may be too small"],
            perceptions: [
                HomePerception(dimension: .light,   polarity: .better, reason: "Full of light all afternoon"),
                HomePerception(dimension: .parking, polarity: .better, reason: "Easy parking right out front"),
            ],
            summary: "Smaller than expected, but bright, walkable, and easy to park — bedroom size to check."
        )
    )

    /// Default for any other home: a warm impression that still notes the light.
    static let warmImpression = DebriefFixture(
        transcript: """
        Really liked this one. Good light through the day, and the parking out front is a \
        relief. I do want to ask the agent how old the roof is — the shingles looked a bit tired.
        """,
        audioResource: "debrief_impression",
        draft: DebriefDraft(
            positives: ["Good light through the day", "Easy parking out front"],
            openQuestions: ["How old is the roof?"],
            perceptions: [
                HomePerception(dimension: .light,   polarity: .better, reason: "Good light through the day"),
                HomePerception(dimension: .parking, polarity: .better, reason: "Easy parking right out front"),
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
        if address.contains("oak")      { return oakSurprise }
        return warmImpression
    }
}
