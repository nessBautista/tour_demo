//
//  Impression.swift
//  tourDemoApp — Modules/Services/Comparison
//
//  One saved debrief, attributed to a single home — the per-home impression
//  stream the feature name promises. Stored append-only in `BuyerMemoryStore`,
//  keyed by home id, so the buyer-memory panel can browse them. Carries the
//  `address` so the panel renders the stream without refetching the listings.
//  Holds only the confirmed, human-facing summary — the scoring effects of a
//  debrief live on the profile/perceptions, not here.
//

import Foundation

struct Impression: Identifiable, Equatable, Sendable {
    let id = UUID()
    let homeID: UUID
    let address: String
    let recordedAt: Date
    let summary: String
    let positives: [String]
    let concerns: [String]
    /// Follow-ups the debrief surfaced (e.g. "how old is the roof?") — the Plan tab
    /// turns these into "ask your agent" next-best-actions.
    let openQuestions: [String]

    init(homeID: UUID,
         address: String,
         summary: String,
         positives: [String],
         concerns: [String],
         openQuestions: [String] = [],
         recordedAt: Date = Date()) {
        self.homeID = homeID
        self.address = address
        self.summary = summary
        self.positives = positives
        self.concerns = concerns
        self.openQuestions = openQuestions
        self.recordedAt = recordedAt
    }
}
