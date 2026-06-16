/// The capability the rest of the system depends on: turn homes into a ranked,
/// explainable ordering for a buyer.
///
/// Callers (the app, the agent's comparison aid) should depend on `HomeRanking`
/// rather than the concrete ``FitScorer``. That inversion is what makes the
/// component composable: a different ranking strategy — a smarter scorer, a stub
/// in a unit test — can be injected without changing a line of caller code.
///
/// ```swift
/// let ranker: any HomeRanking = FitScorer(preferences: profile)
/// let ranked = ranker.rank(homes)
/// ```
public protocol HomeRanking: Sendable {
    /// One home's fit against the buyer profile, with the breakdown that explains it.
    func score(_ home: Home) -> FitScore

    /// All homes ranked, best fit first. A default implementation is provided;
    /// conformers only need `score(_:)`.
    func rank(_ homes: [Home]) -> [FitScore]
}

public extension HomeRanking {
    /// Default ranking: score every home, then order best fit first with a
    /// deterministic tie-break by `id`. Override for a different ordering.
    func rank(_ homes: [Home]) -> [FitScore] {
        homes
            .map(score)
            .sorted { lhs, rhs in
                if lhs.fit != rhs.fit { return lhs.fit > rhs.fit }
                return lhs.home.id < rhs.home.id
            }
    }
}
