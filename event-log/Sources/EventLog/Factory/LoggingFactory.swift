import Foundation

/// A built logging setup: the ``EventLogger`` the app emits through, and the
/// ``InMemoryEventSink`` it can read back for a developer view or a cost rollup.
public struct Logging: Sendable {
    public let logger: EventLogger
    public let store: InMemoryEventSink

    public init(logger: EventLogger, store: InMemoryEventSink) {
        self.logger = logger
        self.store = store
    }
}

/// Builds the app's logging setup. The package owns the wiring decision: always
/// keep events in memory (for the in-app log + cost rollups), and in DEBUG also
/// echo them to the console.
public enum LoggingFactory {
    public static func make() -> Logging {
        let store = InMemoryEventSink()
        #if DEBUG
        let sink: any EventSink = MultiplexEventSink([store, ConsoleEventSink()])
        #else
        let sink: any EventSink = store
        #endif
        return Logging(logger: EventLogger(sink: sink), store: store)
    }
}
