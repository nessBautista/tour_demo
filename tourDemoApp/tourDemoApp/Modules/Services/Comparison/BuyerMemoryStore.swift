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
    /// Where the home sits in the tour funnel (drives the Today affordance).
    let tourState: TourState
    /// How many debriefs are on record for it (shown on a debriefed card).
    let impressionCount: Int

    var id: UUID { home.id }
    var fitPercent: Int { Int(fit.rounded()) }
    /// Booked or debriefed — eligible for Compare.
    var isToured: Bool { tourState.isToured }
}

@MainActor
final class BuyerMemoryStore {
    private(set) var preferences: [Preference]
    /// Per-home, per-dimension overlay (0–100) applied on top of backend ratings.
    private(set) var perceivedRatings: [UUID: [HomeDimension: Int]] = [:]
    private(set) var tourStates: [UUID: TourState] = [:]
    private(set) var impressions: [UUID: [Impression]] = [:]
    /// Recurrence signal: how often each dimension came up across debriefed homes
    /// (the basis for "mentioned at 3/3 homes → promote").
    private(set) var mentions: [HomeDimension: DimensionMentions] = [:]
    /// Profile dimensions whose direction reversed — surfaced, not hidden.
    private(set) var contradictions: [Contradiction] = []

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

    /// Book a tour: advance notToured → booked. Never regresses a debriefed home.
    func book(_ id: UUID) {
        if tourState(of: id).rank < TourState.booked.rank {
            tourStates[id] = .booked
        }
    }

    /// Force a state (DevTools seeding / tests).
    func setTourState(_ state: TourState, for id: UUID) {
        tourStates[id] = state
    }

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
            recordMention(perception, home: home)
        }
        impressions[home.id, default: []].append(
            Impression(homeID: home.id,
                       address: home.address,
                       summary: draft.summary ?? "",
                       positives: draft.positives,
                       concerns: draft.concerns,
                       openQuestions: draft.openQuestions)
        )
        // A debriefed home is, by definition, toured.
        tourStates[home.id] = .debriefed
    }

    /// Latest-wins merge by dimension: a revised preference replaces the prior one
    /// for the same dimension (e.g. yard wantsMore → yard wantsLess), else appends.
    /// A direction flip is recorded as a `Contradiction` for the memory panel.
    private func applyPreference(_ preference: Preference) {
        if let index = preferences.firstIndex(where: { $0.dimension == preference.dimension }) {
            let existing = preferences[index]
            if existing.direction != preference.direction {
                contradictions.append(Contradiction(dimension: preference.dimension,
                                                     previous: existing, latest: preference))
            }
            preferences[index] = preference
        } else {
            preferences.append(preference)
        }
    }

    /// Tally one perception toward its dimension's recurrence across homes.
    private func recordMention(_ perception: HomePerception, home: Home) {
        var entry = mentions[perception.dimension] ?? DimensionMentions()
        entry.homes.insert(home.id)
        switch perception.polarity {
        case .better: entry.better += 1
        case .worse:  entry.worse += 1
        }
        mentions[perception.dimension] = entry
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
                                  tourState: tourState(of: home.id),
                                  impressionCount: impressions(for: home.id).count)
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

    // MARK: Recurrence → promote

    /// Homes with at least one saved debrief (the denominator for recurrence).
    var debriefedHomeCount: Int { impressions.keys.count }

    /// Dimensions that recur across debriefed homes and aren't yet a must-have —
    /// the panel offers each as a confirmation card. A dimension qualifies when it
    /// was mentioned at ≥2 homes AND in at least two-thirds of debriefed homes.
    func promoteSuggestions() -> [PromoteSuggestion] {
        let total = debriefedHomeCount
        guard total >= 2 else { return [] }

        var suggestions: [PromoteSuggestion] = []
        for (dimension, mention) in mentions {
            guard mention.count >= 2, mention.count * 3 >= total * 2 else { continue }

            if let current = preferences.first(where: { $0.dimension == dimension }) {
                // Already tracked → only suggest if there's headroom to raise it.
                guard let bumped = current.importance.next else { continue }
                suggestions.append(PromoteSuggestion(
                    dimension: dimension, mentionedHomes: mention.count, totalHomes: total,
                    proposedDirection: current.direction, proposedImportance: bumped, isNew: false))
            } else {
                // Not in the profile yet → add it, leaning the way the mentions lean.
                let importance: Importance = mention.count == total ? .high : .medium
                suggestions.append(PromoteSuggestion(
                    dimension: dimension, mentionedHomes: mention.count, totalHomes: total,
                    proposedDirection: mention.netDirection, proposedImportance: importance, isNew: true))
            }
        }
        // Strongest recurrence first; dimension name breaks ties (stable for tests).
        return suggestions.sorted {
            $0.mentionedHomes != $1.mentionedHomes
                ? $0.mentionedHomes > $1.mentionedHomes
                : $0.dimension.rawValue < $1.dimension.rawValue
        }
    }

    /// Accept a promotion: write the proposed preference (add or raise importance).
    /// Re-ranking happens wherever `ranked(_:)` is next read (Compare/Today on appear).
    func promote(_ suggestion: PromoteSuggestion) {
        applyPreference(suggestion.preference)
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
