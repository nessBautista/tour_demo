//
//  MemoryInsights.swift
//  tourDemoApp — Modules/Services/Comparison
//
//  The derived, explainable views over buyer memory that the memory panel shows:
//
//   • DimensionMentions — how often a dimension came up across debriefed homes,
//     and which way (the recurrence signal behind "mentioned at 3/3 homes").
//   • Contradiction — a profile dimension whose direction flipped (e.g. a yard
//     went from must-have to wants-less); surfaced, not silently overwritten.
//   • PromoteSuggestion — a recurring dimension the system proposes strengthening
//     (add it, or bump its importance). It becomes a confirmation card the buyer
//     accepts — the same human-in-the-loop gate as onboarding/debrief.
//
//  All three are pure data computed by BuyerMemoryStore; nothing here mutates.
//

import Foundation
import ComparisonCore

/// How often one dimension was mentioned across debriefed homes, with the net lean.
struct DimensionMentions: Equatable, Sendable {
    /// Distinct homes whose debrief mentioned this dimension.
    var homes: Set<UUID> = []
    var better = 0
    var worse = 0

    var count: Int { homes.count }
    /// The way the mentions lean overall — what direction a promotion would propose.
    var netDirection: Direction { better >= worse ? .wantsMore : .wantsLess }
}

/// A profile dimension whose direction reversed across the buyer's history.
struct Contradiction: Identifiable, Equatable, Sendable {
    let id = UUID()
    let dimension: HomeDimension
    let previous: Preference
    let latest: Preference
}

/// A recurring dimension the panel proposes promoting — either adding it to the
/// profile (`isNew`) or raising its importance. Accepting it writes to memory.
struct PromoteSuggestion: Identifiable, Equatable, Sendable {
    let id = UUID()
    let dimension: HomeDimension
    /// Mentioned at `mentionedHomes` of `totalHomes` debriefed homes.
    let mentionedHomes: Int
    let totalHomes: Int
    let proposedDirection: Direction
    let proposedImportance: Importance
    /// True when the dimension isn't in the profile yet (add vs. bump importance).
    let isNew: Bool

    /// The committed preference this suggestion becomes when accepted.
    var preference: Preference {
        Preference(dimension: dimension, direction: proposedDirection, importance: proposedImportance)
    }
}

extension Importance {
    /// The next importance up (low → medium → high); nil when already at the top.
    var next: Importance? {
        switch self {
        case .low:    .medium
        case .medium: .high
        case .high:   nil
        }
    }
}
