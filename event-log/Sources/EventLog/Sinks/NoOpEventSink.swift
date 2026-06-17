import Foundation

/// Discards every event — a safe default where logging is disabled, and a clean
/// stand-in in tests that don't care about output.
public struct NoOpEventSink: EventSink {
    public init() {}
    public func record(_ event: Event) {}
}
