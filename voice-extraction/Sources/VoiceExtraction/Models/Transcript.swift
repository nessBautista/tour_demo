import Foundation

/// The two-tier transcript the on-device transcriber emits.
///
/// `volatile` is the live guess and may be revised on the fly; `finalized` is
/// confirmed and append-only. Keeping them separate is what avoids the classic
/// duplicate-text bug — when a finalized chunk lands, the volatile slate clears.
public struct Transcript: Equatable, Sendable {
    public var volatile: String
    public var finalized: String

    public init(volatile: String = "", finalized: String = "") {
        self.volatile = volatile
        self.finalized = finalized
    }

    /// Everything captured so far: confirmed text plus the live tail.
    public var combined: String {
        finalized + volatile
    }

    public var isEmpty: Bool { volatile.isEmpty && finalized.isEmpty }
}
