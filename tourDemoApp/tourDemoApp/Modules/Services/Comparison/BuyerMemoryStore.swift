//
//  BuyerMemoryStore.swift
//  tourDemoApp — Modules/Services/Comparison
//
//  The shared buyer profile (§6): the current `[Preference]`, single source of
//  truth across tabs. Onboarding sets it; Today (and later Compare) read it to
//  rank homes by fit via the deterministic ComparisonCore `FitScorer`.
//
//  Seeded with the canonical demo buyer so ranking works before onboarding wires
//  in; `setPreferences` replaces it with the confirmed onboarding profile.
//

import Foundation
import ComparisonCore

/// A listing plus its fit against the current buyer profile.
struct ScoredHome: Identifiable, Equatable {
    let home: Home
    /// 0–100 (the importance-weighted match average).
    let fit: Double
    var id: UUID { home.id }
    var fitPercent: Int { Int(fit.rounded()) }
}

@MainActor
final class BuyerMemoryStore {
    private(set) var preferences: [Preference]

    // `nonisolated` so the default argument (evaluated in a nonisolated context)
    // can build a seeded store without hopping the main actor. `[Preference]` is
    // Sendable; the mutating/reading methods below stay main-actor-isolated.
    nonisolated init(preferences: [Preference] = BuyerMemoryStore.seededProfile) {
        self.preferences = preferences
    }

    /// Replace the profile with the buyer-confirmed onboarding preferences.
    func setPreferences(_ preferences: [Preference]) {
        self.preferences = preferences
    }

    /// Homes ranked by fit, best first.
    func ranked(_ homes: [Home]) -> [ScoredHome] {
        let scorer = FitScorer(preferences: preferences)
        return homes
            .map { ScoredHome(home: $0, fit: scorer.score($0.asComparisonHome).fit) }
            .sorted { $0.fit > $1.fit }
    }

    /// Compact one-line profile for logs/eval, e.g. "yard↑3 quiet↑3 commute↑2
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

private extension Home {
    /// Map the listing onto the scorer's input: id + address + the dimension
    /// ratings (string keys → the closed `HomeDimension` vocabulary; unknown keys
    /// are dropped). `Home` here is the app's; `ComparisonCore.Home` is the scorer's.
    var asComparisonHome: ComparisonCore.Home {
        let mapped = Dictionary(uniqueKeysWithValues: ratings.compactMap { key, value in
            HomeDimension(rawValue: key).map { ($0, value) }
        })
        return ComparisonCore.Home(id: id.uuidString, address: address, ratings: mapped)
    }
}
