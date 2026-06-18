//
//  BuyerMemoryRecurrenceTests.swift
//  tourDemoAppTests
//
//  The buyer-memory panel's claim: dimensions that recur across debriefs surface as
//  promote suggestions, and accepting one writes to the profile and re-scores. Plain
//  store calls, deterministic fixtures (iOS architecture §8).
//

import XCTest
import ComparisonCore
@testable import tourDemoApp

@MainActor
final class BuyerMemoryRecurrenceTests: XCTestCase {

    private func debriefAllHomes(_ store: BuyerMemoryStore) {
        for home in FixtureHomesService.demoHomes {   // Alder, Foundry, Bellview
            store.applyDebrief(DebriefFixtures.fixture(for: home).draft, home: home)
        }
    }

    func testLightRecursAcrossHomesAndSurfacesAsANewMustHave() {
        let store = BuyerMemoryStore()
        debriefAllHomes(store)                          // every fixture mentions light

        XCTAssertEqual(store.debriefedHomeCount, 3)
        let suggestions = store.promoteSuggestions()

        guard let light = suggestions.first(where: { $0.dimension == .light }) else {
            return XCTFail("expected a promote suggestion for light")
        }
        XCTAssertTrue(light.isNew)                       // not in the profile yet
        XCTAssertEqual(light.mentionedHomes, 3)
        XCTAssertEqual(light.totalHomes, 3)
        XCTAssertEqual(light.proposedDirection, .wantsMore)   // mentions lean positive
        XCTAssertEqual(light.proposedImportance, .high)       // 3/3 → must-have
        XCTAssertEqual(suggestions.first?.dimension, .light)  // strongest recurrence first
    }

    func testPromotingLightAddsItToTheProfileAndScoresEveryHome() {
        let store = BuyerMemoryStore()
        debriefAllHomes(store)
        XCTAssertFalse(store.preferences.contains { $0.dimension == .light })

        let light = store.promoteSuggestions().first { $0.dimension == .light }!
        store.promote(light)

        XCTAssertTrue(store.preferences.contains {
            $0.dimension == .light && $0.direction == .wantsMore && $0.importance == .high
        })
        // light now contributes to every home's explainable breakdown…
        let scored = store.ranked(FixtureHomesService.demoHomes)
        XCTAssertTrue(scored.allSatisfy { $0.breakdown.contains { $0.preference.dimension == .light } })
        // …and is no longer suggested (it's already a must-have).
        XCTAssertFalse(store.promoteSuggestions().contains { $0.dimension == .light })
    }

    func testRecurrenceNeedsAtLeastTwoHomes() {
        let store = BuyerMemoryStore()
        store.applyDebrief(DebriefFixtures.fixture(for: FixtureHomesService.demoHomes[1]).draft,
                           home: FixtureHomesService.demoHomes[1])   // one home only
        XCTAssertTrue(store.promoteSuggestions().isEmpty)
    }

    func testFlippingYardRecordsAContradiction() {
        let store = BuyerMemoryStore()
        store.applyDebrief(DebriefFixtures.yardTooMuch.draft, home: FixtureHomesService.demoHomes[0])
        XCTAssertTrue(store.contradictions.contains {
            $0.dimension == .yard && $0.previous.direction == .wantsMore && $0.latest.direction == .wantsLess
        })
    }
}
