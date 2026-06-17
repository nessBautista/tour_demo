import XCTest
import Dispatch
import EventLog

final class SinkTests: XCTestCase {

    private func event(_ name: String) -> Event {
        Event(name: name, category: .product)
    }

    func testInMemorySinkRecordsAndClears() {
        let sink = InMemoryEventSink()
        sink.record(event("a"))
        sink.record(event("b"))
        XCTAssertEqual(sink.events.map(\.name), ["a", "b"])

        sink.clear()
        XCTAssertTrue(sink.events.isEmpty)
    }

    func testMultiplexFansOutToEverySink() {
        let a = InMemoryEventSink()
        let b = InMemoryEventSink()
        let fan = MultiplexEventSink([a, b])

        fan.record(event("x"))

        XCTAssertEqual(a.events.map(\.name), ["x"])
        XCTAssertEqual(b.events.map(\.name), ["x"])
    }

    /// The lock behind `@unchecked Sendable` must hold under concurrent writers
    /// (the agent and the UI both record).
    func testInMemorySinkIsConcurrencySafe() {
        let sink = InMemoryEventSink()
        DispatchQueue.concurrentPerform(iterations: 1_000) { i in
            sink.record(event("e\(i)"))
        }
        XCTAssertEqual(sink.events.count, 1_000)
    }
}
