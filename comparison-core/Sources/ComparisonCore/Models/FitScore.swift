/// One preference's contribution to a home's fit — the explainable unit.
public struct DimensionMatch: Sendable, Hashable {
    /// The buyer preference this line answers.
    public let preference: Preference
    /// The home's rating for the preference's dimension, 0–100.
    public let rating: Int
    /// How desirable that rating is to this buyer, 0–100
    /// (`rating` if wantsMore, `100 - rating` if wantsLess).
    public let match: Int
    /// The preference's importance weight (low 1 · medium 2 · high 3).
    public let weight: Int

    public init(preference: Preference, rating: Int, match: Int, weight: Int) {
        self.preference = preference
        self.rating = rating
        self.match = match
        self.weight = weight
    }
}

/// A home scored against a buyer's profile: the overall `fit` plus the
/// per-preference `breakdown` that explains it.
public struct FitScore: Sendable, Identifiable {
    public let home: Home
    /// Overall fit, 0–100 (the importance-weighted average of the matches).
    public let fit: Double
    /// The matches that produced `fit`, in preference order.
    public let breakdown: [DimensionMatch]

    public var id: String { home.id }

    public init(home: Home, fit: Double, breakdown: [DimensionMatch]) {
        self.home = home
        self.fit = fit
        self.breakdown = breakdown
    }
}
