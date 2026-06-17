import Foundation

/// Keeps every event in memory. The backbone of the in-app event log / developer
/// view, the source for cost rollups (``inferenceSummary(pricing:)``), and what
/// tests assert against.
///
/// Thread-safe via a lock, so the agent (background) and the UI (main) can both
/// record concurrently — hence `@unchecked Sendable` (we vouch for the locking
/// the compiler can't see, like the audio `BufferConverter`).
public final class InMemoryEventSink: EventSink, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Event] = []

    public init() {}

    public func record(_ event: Event) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(event)
    }

    /// A snapshot of everything recorded so far, in order.
    public var events: [Event] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}
