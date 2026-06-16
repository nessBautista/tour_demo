/// The deterministic comparison engine — the primary ``HomeRanking`` in
/// `ComparisonCore`.
///
/// A `FitScorer` is configured once with a buyer's **preferences** (their
/// profile) and then scores or ranks homes against that profile. It's a value
/// type: copying is cheap, there's no shared mutable state, and it's `Sendable`,
/// so it's safe to hand across threads. Scoring is pure — no I/O, no randomness,
/// no model in the loop — so the same inputs always produce the same ranking,
/// and every number traces back to a rating and a weight (see `FitScore.breakdown`).
///
/// ## Instantiating
///
/// Create one scorer per buyer profile, then reuse it across as many homes as
/// you like:
///
/// ```swift
/// let scorer = FitScorer(preferences: [
///     Preference(dimension: .yard,  direction: .wantsMore, importance: .high),
///     Preference(dimension: .quiet, direction: .wantsMore, importance: .medium),
/// ])
///
/// let ranked = scorer.rank(homes)   // [FitScore], best fit first
/// let one    = scorer.score(home)   // FitScore for a single home
/// ```
///
/// Prefer depending on the ``HomeRanking`` protocol where you store or inject it,
/// so the concrete engine can be swapped later:
///
/// ```swift
/// let ranker: any HomeRanking = FitScorer(preferences: profile)
/// ```
///
/// ## When the profile changes
///
/// A scorer's profile is immutable. When the buyer's preferences change (e.g. a
/// debrief updates their memory), make a new scorer — cheaply — with
/// ``updating(preferences:)``:
///
/// ```swift
/// let revised = scorer.updating(preferences: newProfile)
/// ```
///
/// This keeps each ranking tied to an explicit, unchanging profile, which is
/// what makes results reproducible.
///
/// ## The math
///
///   match = rating          if wantsMore
///         = 100 - rating     if wantsLess
///
///   fit%  = Σ(weight × match) / Σ(weight)   over the profile's preferences
public struct FitScorer: HomeRanking {

    /// The buyer profile this scorer ranks against.
    public let preferences: [Preference]

    /// Create a scorer for a buyer profile.
    ///
    /// - Parameter preferences: the buyer's preferences. May be empty (every
    ///   home then scores 0 — there is nothing to satisfy). Duplicate
    ///   dimensions are allowed and each counts independently.
    public init(preferences: [Preference]) {
        self.preferences = preferences
    }

    /// How desirable a rating is, given a direction. `wantsMore` → the rating
    /// itself; `wantsLess` → its mirror (`100 - rating`). The rating is clamped
    /// to 0–100 first.
    ///
    /// Static because it depends only on its arguments, not on the profile —
    /// handy for tests and for explaining a single dimension in a UI.
    public static func match(rating: Int, direction: Direction) -> Int {
        let clamped = min(100, max(0, rating))
        switch direction {
        case .wantsMore: return clamped
        case .wantsLess: return 100 - clamped
        }
    }

    /// One home's fit against this scorer's profile: the importance-weighted
    /// average of its matches, plus the per-preference breakdown that explains it.
    public func score(_ home: Home) -> FitScore {
        var weightedSum = 0
        var totalWeight = 0
        var breakdown: [DimensionMatch] = []
        breakdown.reserveCapacity(preferences.count)

        for preference in preferences {
            let rating = home.rating(for: preference.dimension)
            let matchValue = FitScorer.match(rating: rating, direction: preference.direction)
            let weight = preference.importance.weight

            weightedSum += matchValue * weight
            totalWeight += weight
            breakdown.append(
                DimensionMatch(
                    preference: preference,
                    rating: rating,
                    match: matchValue,
                    weight: weight
                )
            )
        }

        let fit = totalWeight == 0 ? 0 : Double(weightedSum) / Double(totalWeight)
        return FitScore(home: home, fit: fit, breakdown: breakdown)
    }

    // `rank(_:)` comes from the HomeRanking default implementation.

    /// A new scorer with a different profile, leaving this one untouched. Use
    /// when the buyer's preferences change.
    public func updating(preferences: [Preference]) -> FitScorer {
        FitScorer(preferences: preferences)
    }
}
