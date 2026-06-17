import XCTest
import ComparisonCore

final class HomeRankingFactoryTests: XCTestCase {

    func testMakeDefaultRanksAgainstGivenProfile() {
        let ranker = HomeRankingFactory.makeDefault(preferences: DemoData.sampleProfile)
        let ranked = ranker.rank(DemoData.homes)
        XCTAssertEqual(ranked.count, DemoData.homes.count)
        XCTAssertEqual(ranked.map(\.fit), ranked.map(\.fit).sorted(by: >))
    }

    func testMakeDefaultWithEmptyProfileScoresZero() {
        let ranker = HomeRankingFactory.makeDefault(preferences: [])
        XCTAssertTrue(ranker.rank(DemoData.homes).allSatisfy { $0.fit == 0 })
    }

    /// makeDemo wires the sample profile, under which Alder Court wins.
    func testMakeDemoUsesSampleProfile() {
        let ranker = HomeRankingFactory.makeDemo()
        let top = ranker.rank(DemoData.homes).first
        XCTAssertEqual(top?.home.address, "412 Alder Court, Maple Grove")
    }
}
