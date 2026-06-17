import Foundation

/// The ergonomic front door to the event system.
///
/// Callers hold an `EventLogger` (not a raw ``EventSink``) and emit events with
/// intent-revealing helpers instead of building ``Event`` values by hand. It's a
/// thin, `Sendable` value over a sink, so it's cheap to pass around and safe to
/// call from the agent loop.
///
/// ```swift
/// logger.log("debrief.recorded", properties: ["home": homeID])
/// logger.inference(model: "claude-opus-4-8", operation: "extraction",
///                  inputTokens: 1200, outputTokens: 300, latencyMS: 840,
///                  traceID: runID)
/// ```
public struct EventLogger: Sendable {
    private let sink: any EventSink

    public init(sink: any EventSink) {
        self.sink = sink
    }

    /// Record a product/system event.
    public func log(
        _ name: String,
        category: EventCategory = .product,
        properties: [String: String] = [:],
        traceID: UUID? = nil
    ) {
        sink.record(
            Event(name: name, category: category, properties: properties, traceID: traceID)
        )
    }

    /// Record a model call — the traceable, costable unit. Named
    /// `inference.<operation>` so it reads well in a stream.
    public func inference(
        model: String,
        operation: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int = 0,
        latencyMS: Int,
        succeeded: Bool = true,
        traceID: UUID? = nil,
        properties: [String: String] = [:]
    ) {
        let metrics = InferenceMetrics(
            model: model,
            operation: operation,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            latencyMS: latencyMS,
            succeeded: succeeded
        )
        sink.record(
            Event(
                name: "inference.\(operation)",
                category: .inference,
                properties: properties,
                traceID: traceID,
                inference: metrics
            )
        )
    }
}
