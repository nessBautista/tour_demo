import Foundation

/// A lookup of ``ModelPricing`` by model id, plus the cost math.
///
/// Pricing is configuration, not history: cost is computed on demand from
/// recorded ``InferenceMetrics``, so updating rates never rewrites past events.
/// A model with no entry yields `nil` cost (e.g. an on-device model that's free,
/// or one we simply haven't priced) — surfaced, never silently zero.
public struct PricingBook: Sendable {
    private let rates: [String: ModelPricing]

    public init(_ rates: [String: ModelPricing]) {
        self.rates = rates
    }

    public func pricing(for model: String) -> ModelPricing? {
        rates[model]
    }

    /// USD cost of one model call, or `nil` if the model isn't priced.
    public func costUSD(for metrics: InferenceMetrics) -> Double? {
        guard let p = rates[metrics.model] else { return nil }
        let dollars =
            Double(metrics.inputTokens) * p.inputPerMTok
            + Double(metrics.cacheReadTokens) * p.cacheReadPerMTok
            + Double(metrics.outputTokens) * p.outputPerMTok
        return dollars / 1_000_000
    }
}

public extension PricingBook {
    /// Anthropic list prices, USD per million tokens — a dated snapshot
    /// (cache-read ≈ 0.1× input). Update when prices change.
    ///
    /// Even when the demo's agent runs on-device (free), this lets us *estimate*
    /// what each inference would cost on cloud models — directly useful for
    /// deciding what's worth automating, and at what price.
    static let anthropicJune2026 = PricingBook([
        "claude-fable-5":    ModelPricing(inputPerMTok: 10, outputPerMTok: 50, cacheReadPerMTok: 1.0),
        "claude-opus-4-8":   ModelPricing(inputPerMTok: 5,  outputPerMTok: 25, cacheReadPerMTok: 0.5),
        "claude-sonnet-4-6": ModelPricing(inputPerMTok: 3,  outputPerMTok: 15, cacheReadPerMTok: 0.3),
        "claude-haiku-4-5":  ModelPricing(inputPerMTok: 1,  outputPerMTok: 5,  cacheReadPerMTok: 0.1),
    ])
}
