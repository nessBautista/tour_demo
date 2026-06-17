import XCTest
import EventLog

final class PricingTests: XCTestCase {

    private let book = PricingBook.anthropicJune2026

    /// Opus 4.8: 1M input × $5 + 1M output × $25 = $30, all in one call.
    func testCostIsHandComputable() {
        let m = InferenceMetrics(
            model: "claude-opus-4-8", operation: "x",
            inputTokens: 1_000_000, outputTokens: 1_000_000, latencyMS: 0
        )
        XCTAssertEqual(book.costUSD(for: m) ?? -1, 30.0, accuracy: 0.0001)
    }

    func testCacheReadBillsAtReducedRate() {
        // 1M cache-read tokens on Opus 4.8 at $0.5/MTok = $0.50.
        let m = InferenceMetrics(
            model: "claude-opus-4-8", operation: "x",
            inputTokens: 0, outputTokens: 0, cacheReadTokens: 1_000_000, latencyMS: 0
        )
        XCTAssertEqual(book.costUSD(for: m) ?? -1, 0.5, accuracy: 0.0001)
    }

    func testUnpricedModelReturnsNil() {
        let m = InferenceMetrics(
            model: "on-device", operation: "x",
            inputTokens: 1_000, outputTokens: 1_000, latencyMS: 0
        )
        XCTAssertNil(book.costUSD(for: m))
    }

    func testHaikuIsCheapestTier() {
        XCTAssertEqual(book.pricing(for: "claude-haiku-4-5")?.inputPerMTok, 1)
        XCTAssertEqual(book.pricing(for: "claude-fable-5")?.outputPerMTok, 50)
    }
}
