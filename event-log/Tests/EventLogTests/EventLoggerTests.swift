import XCTest
import EventLog

final class EventLoggerTests: XCTestCase {

    func testLogRecordsAProductEvent() {
        let store = InMemoryEventSink()
        let logger = EventLogger(sink: store)

        logger.log("debrief.recorded", properties: ["home": "alder"])

        let event = store.events.first
        XCTAssertEqual(store.events.count, 1)
        XCTAssertEqual(event?.name, "debrief.recorded")
        XCTAssertEqual(event?.category, .product)
        XCTAssertEqual(event?.properties["home"], "alder")
        XCTAssertNil(event?.inference)
    }

    func testInferenceRecordsMetricsAndNames() {
        let store = InMemoryEventSink()
        let logger = EventLogger(sink: store)
        let run = UUID()

        logger.inference(
            model: "claude-opus-4-8",
            operation: "extraction",
            inputTokens: 1200,
            outputTokens: 300,
            latencyMS: 840,
            traceID: run
        )

        let event = store.events.first
        XCTAssertEqual(event?.name, "inference.extraction")
        XCTAssertEqual(event?.category, .inference)
        XCTAssertEqual(event?.traceID, run)
        XCTAssertEqual(event?.inference?.model, "claude-opus-4-8")
        XCTAssertEqual(event?.inference?.totalTokens, 1500)
    }

    func testTraceIDCorrelatesEvents() {
        let store = InMemoryEventSink()
        let logger = EventLogger(sink: store)
        let run = UUID()

        logger.log("agent.started", category: .system, traceID: run)
        logger.inference(model: "m", operation: "extraction",
                         inputTokens: 1, outputTokens: 1, latencyMS: 1, traceID: run)

        XCTAssertEqual(store.events.filter { $0.traceID == run }.count, 2)
    }
}
