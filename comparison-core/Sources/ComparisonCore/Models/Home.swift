/// A home as the comparison core sees it: an identity plus a per-dimension
/// rating. Ratings are the *amount* of each trait on a 0–100 scale, where higher
/// means more (more yard, shorter commute, quieter).
///
/// This is intentionally a thin, scoring-only view — addresses and prices live
/// in the listings backend; here we only carry what the fit math needs.
public struct Home: Codable, Sendable, Identifiable {
    public let id: String
    public let address: String
    /// Per-dimension ratings, 0–100. A dimension absent here is treated as 0.
    public let ratings: [HomeDimension: Int]

    public init(id: String, address: String, ratings: [HomeDimension: Int]) {
        self.id = id
        self.address = address
        self.ratings = ratings
    }

    /// The home's rating for a dimension, clamped to 0–100. A dimension the home
    /// doesn't rate counts as 0 — no evidence of the trait (e.g. yard = 0 for a
    /// home with no yard).
    public func rating(for dimension: HomeDimension) -> Int {
        let raw = ratings[dimension] ?? 0
        return min(100, max(0, raw))
    }
}
