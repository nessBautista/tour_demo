//
//  OnboardingFixtures.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The canonical onboarding script paired with the extraction a good run produces
//  (mocking the LLM: design onBoarding02 transcript → onBoarding04 cards). The four
//  proposals use the scored comparison vocabulary, so confirming them sets a real
//  buyer profile the FitScorer ranks against. They mirror BuyerMemoryStore's seeded
//  profile, so the ranking is consistent whether or not onboarding is run.
//
//  The fixture audio the recording screen plays should say roughly this transcript,
//  so the streamed captions line up. One place to edit if the audio changes.
//

import Foundation
import ComparisonCore

struct OnboardingFixture: Sendable {
    let transcript: String
    let draft: OnboardingDraft
}

enum OnboardingFixtures {
    /// A family with a dog: a real yard and a quiet street (must-haves), a short
    /// downtown commute and a kitchen to cook in (nice-to-haves).
    static let standard = OnboardingFixture(
        transcript: """
        A real yard would be amazing — we've got a dog and the kids need space. \
        I'm downtown three days a week, so the commute genuinely matters. And quiet — \
        after four years above a bar, a quiet street is everything. Oh, and a kitchen \
        with room to actually cook.
        """,
        draft: OnboardingDraft(
            preferences: [
                PreferenceProposal(kind: .mustHave,   title: "A real yard",     quote: "a real yard would be amazing",
                                   dimension: .yard,    direction: .wantsMore, importance: .high),
                PreferenceProposal(kind: .mustHave,   title: "A quiet street",  quote: "after four years above a bar",
                                   dimension: .quiet,   direction: .wantsMore, importance: .high),
                PreferenceProposal(kind: .niceToHave, title: "A short commute", quote: "downtown three days a week",
                                   dimension: .commute, direction: .wantsMore, importance: .medium),
                PreferenceProposal(kind: .niceToHave, title: "Room to cook",    quote: "room to actually cook",
                                   dimension: .kitchen, direction: .wantsMore, importance: .medium),
            ],
            summary: "A family with a dog after a real yard and a quiet street, a short downtown commute, and a kitchen to cook in."
        )
    )
}
