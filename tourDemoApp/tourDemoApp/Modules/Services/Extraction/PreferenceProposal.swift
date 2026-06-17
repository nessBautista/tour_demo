//
//  PreferenceProposal.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  One proposed preference from onboarding extraction — the pre-commit shape that
//  maps 1:1 to a confirmation card (design: onBoarding04). Self-contained for now:
//  a badge kind + a title + the buyer's own words. When comparison-core is wired
//  in, these map onto the committed `Preference` vocabulary (dimension/importance/
//  direction); kept deliberately small here so onboarding doesn't depend on it yet.
//

import Foundation

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
    /// Short card title, e.g. "3+ bedrooms".
    let title: String
    /// The buyer's own words, shown in quotes under the title.
    let quote: String
}
