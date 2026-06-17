import Foundation

/// Fans one event out to several sinks — e.g. keep it in memory *and* echo it to
/// the console, with a remote writer added later. The composability the protocol
/// exists for.
public struct MultiplexEventSink: EventSink {
    private let sinks: [any EventSink]

    public init(_ sinks: [any EventSink]) {
        self.sinks = sinks
    }

    public func record(_ event: Event) {
        for sink in sinks {
            sink.record(event)
        }
    }
}
