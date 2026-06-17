import Foundation

/// The measurable detail of a single model call — the part that makes inference
/// *traceable* and *costable*.
///
/// Token counts come straight from the model response's usage (input / output,
/// plus cache-read tokens which bill at a fraction of input). Cost is *not*
/// stored here — it's derived from a ``PricingBook`` at report time, so a price
/// change never invalidates recorded history.
public struct InferenceMetrics: Sendable, Equatable, Codable {
    /// The model id, e.g. `"claude-opus-4-8"` (or `"on-device"` for a local model).
    public let model: String
    /// What the call was for, e.g. `"extraction"` or `"comparison-aid"`.
    public let operation: String
    public let inputTokens: Int
    public let outputTokens: Int
    /// Tokens served from the prompt cache (bill at ~0.1× input).
    public let cacheReadTokens: Int
    public let latencyMS: Int
    public let succeeded: Bool

    public init(
        model: String,
        operation: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int = 0,
        latencyMS: Int,
        succeeded: Bool = true
    ) {
        self.model = model
        self.operation = operation
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.latencyMS = latencyMS
        self.succeeded = succeeded
    }

    public var totalTokens: Int { inputTokens + outputTokens + cacheReadTokens }
}
