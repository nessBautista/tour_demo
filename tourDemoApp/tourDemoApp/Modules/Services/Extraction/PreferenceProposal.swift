//
//  PreferenceProposal.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  One proposed preference from onboarding extraction — the pre-commit shape that
//  maps 1:1 to a confirmation card (design: onBoarding04). Carries both the card
//  display (badge kind + title + the buyer's words) and the comparison vocabulary
//  (dimension/direction/importance) so a confirmed proposal becomes a committed
//  `Preference` the scorer reads.
//

import Foundation
import ComparisonCore

struct PreferenceProposal: Identifiable, Sendable {
    /// The badge shown on the card.
    enum Kind: Sendable {
        case mustHave, niceToHave, priority

        var badge: String {
            switch self {
            case .mustHave:   "MUST-HAVE"
            case .niceToHave: "NICE-TO-HAVE"
            case .priority:   "PRIORITY"
            }
        }
    }

    let id = UUID()
    let kind: Kind
    /// Short card title, e.g. "A real yard".
    let title: String
    /// The buyer's own words, shown in quotes under the title.
    let quote: String

    // Comparison vocabulary — what the scorer reads once the buyer confirms it.
    let dimension: HomeDimension
    let direction: Direction
    let importance: Importance

    /// The committed preference this proposal becomes when confirmed.
    var preference: Preference {
        Preference(dimension: dimension, direction: direction, importance: importance)
    }
}
