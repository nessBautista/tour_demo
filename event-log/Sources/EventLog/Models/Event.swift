import Foundation

/// One thing that happened — the unit the whole app and the agent emit.
///
/// A `product`/`system` event is name + properties; an `inference` event also
/// carries ``InferenceMetrics``. `traceID` correlates the events of one logical
/// flow (a debrief, an agent run) so a whole trajectory can be reconstructed.
///
/// `Codable`, so events can later be shipped to the backend `events` table
/// (jsonb) without a separate DTO.
public struct Event: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let timestamp: Date
    /// Dotted, stable name, e.g. `"debrief.recorded"`, `"preference.accepted"`.
    public let name: String
    public let category: EventCategory
    /// Free-form context (home id, screen, error message). Typed metrics that
    /// matter (tokens, latency) live on ``inference`` instead.
    public let properties: [String: String]
    /// Correlates events from one logical flow (a debrief, an agent run).
    public let traceID: UUID?
    /// Present iff `category == .inference`.
    public let inference: InferenceMetrics?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        name: String,
        category: EventCategory,
        properties: [String: String] = [:],
        traceID: UUID? = nil,
        inference: InferenceMetrics? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.category = category
        self.properties = properties
        self.traceID = traceID
        self.inference = inference
    }
}
