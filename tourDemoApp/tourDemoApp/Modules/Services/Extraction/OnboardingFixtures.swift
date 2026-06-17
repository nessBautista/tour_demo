//
//  OnboardingFixtures.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The canonical onboarding script paired with the extraction a good run produces
//  (design: onBoarding02 transcript + onBoarding04 cards). The fixture audio the
//  recording screen plays should say roughly this transcript, so the streamed
//  captions line up. One place to edit if the audio changes.
//

import Foundation

struct OnboardingFixture: Sendable {
    let transcript: String
    let draft: OnboardingDraft
}

enum OnboardingFixtures {
    /// A family of light sleepers with kids: three bedrooms, a real yard, a short
    /// downtown commute, a quiet street. ~4 preferences.
    static let standard = OnboardingFixture(
        transcript: """
        Okay — we need at least three bedrooms; the kids can't share forever. \
        A real yard would be amazing. I'm downtown three days a week, so the commute \
        genuinely matters. And quiet — after four years above a bar, a quiet street \
        is everything.
        """,
        draft: OnboardingDraft(
            preferences: [
                PreferenceProposal(kind: .mustHave,   title: "3+ bedrooms",       quote: "the kids can't share forever"),
                PreferenceProposal(kind: .niceToHave, title: "A real yard",        quote: "a real yard would be amazing"),
                PreferenceProposal(kind: .priority,   title: "Commute downtown",   quote: "downtown three days a week"),
                PreferenceProposal(kind: .mustHave,   title: "A quiet street",     quote: "after four years above a bar"),
            ],
            summary: "A family with kids after a quiet three-bedroom with a real yard and a short downtown commute."
        )
    )
}
