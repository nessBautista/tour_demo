//
//  Impression.swift
//  tourDemoApp — Modules/Services/Comparison
//
//  One saved debrief, attributed to a single home — the per-home impression
//  stream the feature name promises. Stored append-only in `BuyerMemoryStore`,
//  keyed by home id, so the buyer-memory panel (a later PR) can browse them.
//  Holds only the confirmed, human-facing summary — the scoring effects of a
//  debrief live on the profile/perceptions, not here.
//

import Foundation

struct Impression: Identifiable, Equatable, Sendable {
    let id = UUID()
    let homeID: UUID
    let recordedAt: Date
    let summary: String
    let positives: [String]
    let concerns: [String]

    init(homeID: UUID,
         summary: String,
         positives: [String],
         concerns: [String],
         recordedAt: Date = Date()) {
        self.homeID = homeID
        self.summary = summary
        self.positives = positives
        self.concerns = concerns
        self.recordedAt = recordedAt
    }
}
