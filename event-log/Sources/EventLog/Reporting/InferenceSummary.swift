import Foundation

/// A cost/usage rollup over a set of events — the "what have we spent" answer
/// for product iteration.
public struct InferenceSummary: Sendable, Equatable {
    public let calls: Int
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    /// Summed cost of the calls whose model is priced.
    public let totalCostUSD: Double
    /// Models seen but absent from the pricing book — their calls are counted,
    /// but contribute 0 to `totalCostUSD`. Surfaced so the gap is visible.
    public let unpricedModels: [String]

    public var totalTokens: Int { inputTokens + outputTokens + cacheReadTokens }
}

public extension Sequence where Element == Event {
    /// Roll up the inference events in this sequence against a ``PricingBook``.
    /// Non-inference events are ignored.
    func inferenceSummary(pricing: PricingBook) -> InferenceSummary {
        var calls = 0
        var input = 0
        var output = 0
        var cacheRead = 0
        var cost = 0.0
        var unpriced = Set<String>()

        for event in self {
            guard let m = event.inference else { continue }
            calls += 1
            input += m.inputTokens
            output += m.outputTokens
            cacheRead += m.cacheReadTokens
            if let c = pricing.costUSD(for: m) {
                cost += c
            } else {
                unpriced.insert(m.model)
            }
        }

        return InferenceSummary(
            calls: calls,
            inputTokens: input,
            outputTokens: output,
            cacheReadTokens: cacheRead,
            totalCostUSD: cost,
            unpricedModels: unpriced.sorted()
        )
    }
}
