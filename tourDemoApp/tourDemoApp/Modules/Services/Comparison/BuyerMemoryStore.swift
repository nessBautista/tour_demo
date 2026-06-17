//
//  BuyerMemoryStore.swift
//  tourDemoApp — Modules/Services/Comparison
//
//  The shared buyer memory (§6): the single source of truth the tabs rank against.
//  It holds three things and one derived view:
//
//   • `preferences` — the global profile. Onboarding seeds it; a debrief can revise
//     it (latest-wins per dimension), which re-ranks EVERY home.
//   • `perceivedRatings` — per-home rating overlays from debriefs: what the buyer
//     saw in person, layered over the listing's backend ratings for THIS home only.
//   • `tourStates` / `impressions` — which homes are toured, and the append-only
//     stream of confirmed debriefs per home.
//
//  `ranked(_:)` is the derived view: it scores each home (backend ratings + its
//  perception overlay) through the deterministic ComparisonCore `FitScorer`.
//
//  Pull-based and not observable on purpose (§6): tabs re-read it on appear / after
//  an action rather than binding to it.
//

import Foundation
import ComparisonCore

/// A listing plus its fit against the current buyer memory, and the explainable
/// breakdown behind that fit. `breakdown` powers Compare; Today ignores it.
struct ScoredHome: Identifiable, Equatable {
    let home: Home
    /// 0–100 (the importance-weighted match average).
    let fit: Double
    /// The per-preference matches that produced `fit`, in profile order.
    let breakdown: [DimensionMatch]
    /// Whether the buyer has toured this home (gates the debrief entry point).
    let isToured: Bool

    var id: UUID { home.id }
    var fitPercent: Int { Int(fit.rounded()) }
}

@MainActor
final class BuyerMemoryStore {
    private(set) var preferences: [Preference]
    /// Per-home, per-dimension overlay (0–100) applied on top of backend ratings.
    private(set) var perceivedRatings: [UUID: [HomeDimension: Int]] = [:]
    private(set) var tourStates: [UUID: TourState] = [:]
    private(set) var impressions: [UUID: [Impression]] = [:]

    // `nonisolated` so the default argument (evaluated in a nonisolated context)
    // can build a seeded store without hopping the main actor. `[Preference]` is
    // Sendable; the mutating/reading methods below stay main-actor-isolated.
    nonisolated init(preferences: [Preference] = BuyerMemoryStore.seededProfile) {
        self.preferences = preferences
    }

    // MARK: Profile

    /// Replace the profile with the buyer-confirmed onboarding preferences.
    func setPreferences(_ preferences: [Preference]) {
        self.preferences = preferences
    }

    // MARK: Tour state

    func tourState(of id: UUID) -> TourState { tourStates[id] ?? .notToured }

    func markToured(_ id: UUID) { tourStates[id] = .toured }

    // MARK: Impressions

    func impressions(for id: UUID) -> [Impression] { impressions[id] ?? [] }

    // MARK: Debrief

    /// Commit a confirmed debrief: revise the global profile, re-rate this home,
    /// record the impression, and mark it toured. Order matters — preference
    /// updates land first so perception steps read the up-to-date direction.
    func applyDebrief(_ draft: DebriefDraft, home: Home) {
        for proposal in draft.preferenceUpdates {
            applyPreference(proposal.preference)
        }
        for perception in draft.perceptions {
            adjust(home: home, perception)
        }
        impressions[home.id, default: []].append(
            Impression(homeID: home.id,
                       summary: draft.summary ?? "",
                       positives: draft.positives,
                       concerns: draft.concerns)
        )
        markToured(home.id)
    }

    /// Latest-wins merge by dimension: a revised preference replaces the prior one
    /// for the same dimension (e.g. yard wantsMore → yard wantsLess), else appends.
    private func applyPreference(_ preference: Preference) {
        if let index = preferences.firstIndex(where: { $0.dimension == preference.dimension }) {
            preferences[index] = preference
        } else {
            preferences.append(preference)
        }
    }

    /// Nudge ONE home's perceived rating on a dimension. The step is chosen so the
    /// resulting *match* always moves the way the polarity says (worse → lower fit,
    /// better → higher fit), whichever direction the buyer currently wants — so a
    /// "worse" reaction never accidentally improves the score via `wantsLess`.
    private func adjust(home: Home, _ perception: HomePerception) {
        let dimension = perception.dimension
        let direction = preferences.first { $0.dimension == dimension }?.direction ?? .wantsMore
        let base = perceivedRatings[home.id]?[dimension]
            ?? home.ratings[dimension.rawValue]
            ?? 50
        let step = perception.polarity == .worse ? 25 : 15
        let improves = perception.polarity == .better
        // Raise the underlying rating only when "more of the trait" == "better here".
        let raise = (direction == .wantsMore) == improves
        let next = max(0, min(100, base + (raise ? step : -step)))
        perceivedRatings[home.id, default: [:]][dimension] = next
    }

    // MARK: Ranking

    /// Homes ranked by fit, best first — backend ratings overlaid with each home's
    /// perception adjustments, scored against the current profile.
    func ranked(_ homes: [Home]) -> [ScoredHome] {
        let scorer = FitScorer(preferences: preferences)
        return homes
            .map { home in
                let score = scorer.score(comparisonHome(for: home))
                return ScoredHome(home: home,
                                  fit: score.fit,
                                  breakdown: score.breakdown,
                                  isToured: tourState(of: home.id).isToured)
            }
            .sorted { $0.fit > $1.fit }
    }

    /// Map the listing onto the scorer's input: string ratings → the closed
    /// `HomeDimension` vocabulary, then the per-home perception overlay on top.
    private func comparisonHome(for home: Home) -> ComparisonCore.Home {
        var mapped = Dictionary(uniqueKeysWithValues: home.ratings.compactMap { key, value in
            HomeDimension(rawValue: key).map { ($0, value) }
        })
        if let overlay = perceivedRatings[home.id] {
            for (dimension, value) in overlay { mapped[dimension] = value }
        }
        return ComparisonCore.Home(id: home.id.uuidString, address: home.address, ratings: mapped)
    }

    // MARK: Debug summary

    /// Compact one-line profile for logs/eval, e.g. "yard↓3 quiet↑3 commute↑2
    /// kitchen↑2" — dimension, direction (↑ wantsMore / ↓ wantsLess), weight.
    var summary: String {
        preferences.map { p in
            "\(p.dimension.rawValue)\(p.direction == .wantsMore ? "↑" : "↓")\(p.importance.weight)"
        }
        .joined(separator: " ")
    }

    /// The canonical demo buyer until onboarding overwrites it: a family wanting a
    /// real yard and quiet (must-haves), a short commute and room to cook (nice).
    nonisolated static let seededProfile: [Preference] = [
        Preference(dimension: .yard,    direction: .wantsMore, importance: .high),
        Preference(dimension: .quiet,   direction: .wantsMore, importance: .high),
        Preference(dimension: .commute, direction: .wantsMore, importance: .medium),
        Preference(dimension: .kitchen, direction: .wantsMore, importance: .medium),
    ]
}
