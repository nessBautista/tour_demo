import XCTest
import ComparisonCore

final class FitScorerTests: XCTestCase {

    // MARK: match

    func testMatchWantsMoreIsRatingItself() {
        XCTAssertEqual(FitScorer.match(rating: 80, direction: .wantsMore), 80)
    }

    func testMatchWantsLessMirrorsRating() {
        XCTAssertEqual(FitScorer.match(rating: 80, direction: .wantsLess), 20)
    }

    /// The SOLUTION §3 example: a home with no yard (rating 0). Wanting a yard
    /// scores 0; wanting *less* yard scores 100 — same home, opposite satisfaction.
    func testYardZeroExample() {
        XCTAssertEqual(FitScorer.match(rating: 0, direction: .wantsMore), 0)
        XCTAssertEqual(FitScorer.match(rating: 0, direction: .wantsLess), 100)
    }

    func testMatchClampsOutOfRangeRatings() {
        XCTAssertEqual(FitScorer.match(rating: 150, direction: .wantsMore), 100)
        XCTAssertEqual(FitScorer.match(rating: -10, direction: .wantsMore), 0)
    }

    // MARK: fit

    /// (3 × 80 + 1 × 60) / (3 + 1) = 300 / 4 = 75.
    func testWeightedFitIsHandComputable() {
        let home = Home(id: "h", address: "A", ratings: [.yard: 80, .commute: 40])
        let scorer = FitScorer(preferences: [
            Preference(dimension: .yard, direction: .wantsMore, importance: .high),
            Preference(dimension: .commute, direction: .wantsLess, importance: .low),
        ])
        XCTAssertEqual(scorer.score(home).fit, 75, accuracy: 0.0001)
    }

    func testMissingRatingCountsAsZero() {
        let home = Home(id: "h", address: "A", ratings: [:])
        let scorer = FitScorer(preferences: [
            Preference(dimension: .yard, direction: .wantsMore, importance: .high)
        ])
        XCTAssertEqual(scorer.score(home).fit, 0, accuracy: 0.0001)
    }

    func testEmptyPreferencesGivesZeroFit() {
        let home = Home(id: "h", address: "A", ratings: [.yard: 80])
        XCTAssertEqual(FitScorer(preferences: []).score(home).fit, 0)
    }

    func testBreakdownMirrorsInputs() {
        let home = Home(id: "h", address: "A", ratings: [.quiet: 30])
        let scorer = FitScorer(preferences: [
            Preference(dimension: .quiet, direction: .wantsLess, importance: .medium)
        ])
        let line = scorer.score(home).breakdown.first
        XCTAssertEqual(line?.rating, 30)
        XCTAssertEqual(line?.match, 70)   // 100 - 30
        XCTAssertEqual(line?.weight, 2)   // medium
    }

    // MARK: rank

    func testRankOrdersByFitDescending() {
        let scorer = FitScorer(preferences: DemoData.sampleProfile)
        let fits = scorer.rank(DemoData.homes).map(\.fit)
        XCTAssertEqual(fits, fits.sorted(by: >))
    }

    /// Equal fit must resolve to a stable, input-order-independent order (by id).
    func testRankTieBreaksDeterministicallyById() {
        let scorer = FitScorer(preferences: [
            Preference(dimension: .yard, direction: .wantsMore, importance: .high)
        ])
        let a = Home(id: "a", address: "A", ratings: [.yard: 50])
        let b = Home(id: "b", address: "B", ratings: [.yard: 50])
        XCTAssertEqual(scorer.rank([b, a]).map(\.home.id), ["a", "b"])
    }

    func testImportanceWeightsAreOneTwoThree() {
        XCTAssertEqual(Importance.low.weight, 1)
        XCTAssertEqual(Importance.medium.weight, 2)
        XCTAssertEqual(Importance.high.weight, 3)
    }

    // MARK: instance lifecycle

    func testScorerRetainsItsProfile() {
        let scorer = FitScorer(preferences: DemoData.sampleProfile)
        XCTAssertEqual(scorer.preferences, DemoData.sampleProfile)
    }

    func testUpdatingReturnsAnIndependentScorer() {
        let original = FitScorer(preferences: DemoData.sampleProfile)
        let revised = original.updating(preferences: [])
        XCTAssertEqual(original.preferences, DemoData.sampleProfile)  // value untouched
        XCTAssertTrue(revised.preferences.isEmpty)
    }

    /// The engine is usable purely through the abstraction it's meant to be
    /// injected as — the composability the protocol exists for.
    func testUsableThroughHomeRankingProtocol() {
        let ranker: any HomeRanking = FitScorer(preferences: DemoData.sampleProfile)
        let ranked = ranker.rank(DemoData.homes)
        XCTAssertEqual(ranked.count, DemoData.homes.count)
        XCTAssertEqual(ranked.map(\.fit), ranked.map(\.fit).sorted(by: >))
    }
}
