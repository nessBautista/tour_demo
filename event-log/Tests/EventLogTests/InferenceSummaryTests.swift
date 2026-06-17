import XCTest
import EventLog

final class InferenceSummaryTests: XCTestCase {

    func testSummaryTotalsTokensCostAndFlagsUnpriced() {
        let events: [Event] = [
            Event(name: "debrief.recorded", category: .product),  // ignored
            Event(name: "inference.extraction", category: .inference,
                  inference: InferenceMetrics(
                    model: "claude-opus-4-8", operation: "extraction",
                    inputTokens: 1_000_000, outputTokens: 0, latencyMS: 10)),
            Event(name: "inference.compare", category: .inference,
                  inference: InferenceMetrics(
                    model: "on-device", operation: "compare",
                    inputTokens: 1_000_000, outputTokens: 0, latencyMS: 10)),
        ]

        let summary = events.inferenceSummary(pricing: .anthropicJune2026)

        XCTAssertEqual(summary.calls, 2)                 // product event ignored
        XCTAssertEqual(summary.inputTokens, 2_000_000)
        XCTAssertEqual(summary.outputTokens, 0)
        XCTAssertEqual(summary.totalCostUSD, 5.0, accuracy: 0.0001)  // only Opus priced
        XCTAssertEqual(summary.unpricedModels, ["on-device"])
    }

    func testEmptyEventsSummariseToZero() {
        let summary = [Event]().inferenceSummary(pricing: .anthropicJune2026)
        XCTAssertEqual(summary.calls, 0)
        XCTAssertEqual(summary.totalCostUSD, 0)
        XCTAssertTrue(summary.unpricedModels.isEmpty)
    }
}
