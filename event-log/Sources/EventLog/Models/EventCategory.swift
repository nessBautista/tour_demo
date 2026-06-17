import Foundation

/// What kind of thing an ``Event`` records.
///
/// - `product`: user / funnel actions (onboarding done, debrief recorded, preference accepted).
/// - `inference`: a model call — carries ``InferenceMetrics`` for cost/latency tracking.
/// - `system`: lifecycle, navigation, and errors.
public enum EventCategory: String, Codable, Sendable, CaseIterable {
    case product
    case inference
    case system
}
