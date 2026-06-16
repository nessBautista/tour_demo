/// Which way a buyer wants a dimension to go.
///
/// Ratings are normalised so higher always means "more of the trait" (more yard,
/// shorter commute, quieter). Direction says whether that's what the buyer wants:
/// `wantsMore` takes the rating as-is; `wantsLess` mirrors it.
public enum Direction: String, Codable, Sendable {
    case wantsMore
    case wantsLess
}

/// How much a dimension matters to the buyer. The raw value is the weight used
/// in the fit average, so importance and weight are the same number.
public enum Importance: Int, CaseIterable, Codable, Sendable {
    case low = 1
    case medium = 2
    case high = 3

    /// Weight contributed to the fit average (low 1 · medium 2 · high 3).
    public var weight: Int { rawValue }
}

/// The closed vocabulary of comparable dimensions.
///
/// Keeping this a fixed enum (rather than free-form strings) is what makes the
/// comparison deterministic and explainable: a buyer's preferences and a home's
/// ratings can only ever talk about the same known set of traits.
///
/// `note` is part of the vocabulary for descriptive capture; it carries no
/// inherent "more is better" meaning, so it's typically left out of scoring.
public enum HomeDimension: String, CaseIterable, Codable, Sendable {
    case yard
    case commute
    case quiet
    case kitchen
    case light
    case parking
    case budget
    case note
}


/// One line of a buyer's profile: a dimension plus how (direction) and how much
/// (importance) they care about it.
public struct Preference: Codable, Hashable, Sendable {
    public let dimension: HomeDimension
    public let direction: Direction
    public let importance: Importance

    public init(dimension: HomeDimension, direction: Direction, importance: Importance) {
        self.dimension = dimension
        self.direction = direction
        self.importance = importance
    }
}
