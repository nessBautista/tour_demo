import Foundation

/// Per-model token rates, in USD per **million** tokens.
///
/// Cache-read tokens bill at roughly a tenth of input. Cache *writes* are not
/// modelled here — the demo doesn't track them, and adding them is a field, not
/// a redesign, if needed later.
public struct ModelPricing: Sendable, Equatable {
    public let inputPerMTok: Double
    public let outputPerMTok: Double
    public let cacheReadPerMTok: Double

    public init(inputPerMTok: Double, outputPerMTok: Double, cacheReadPerMTok: Double) {
        self.inputPerMTok = inputPerMTok
        self.outputPerMTok = outputPerMTok
        self.cacheReadPerMTok = cacheReadPerMTok
    }
}
