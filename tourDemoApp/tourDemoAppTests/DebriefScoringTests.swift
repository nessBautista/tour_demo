//
//  DebriefScoringTests.swift
//  tourDemoAppTests
//
//  The feature's core claim: a confirmed debrief rewrites the ranking deterministically.
//  Stores and ViewModels are plain objects — apply a draft, assert the new order
//  (iOS architecture §8). Math traces to the ComparisonCore FitScorer.
//

import XCTest
import ComparisonCore
@testable import tourDemoApp

@MainActor
final class DebriefScoringTests: XCTestCase {

    // MARK: Store

    func testDebriefFlipsYardAndDropsTheFrontRunner() {
        let store = BuyerMemoryStore()                 // seeded profile: yard wantsMore high…
        let homes = FixtureHomesService.demoHomes
        let alder = homes[0]

        // Before: the yard-heavy home leads.
        let before = store.ranked(homes)
        XCTAssertTrue(before.first?.home.address.hasPrefix("412 Alder") ?? false)
        XCTAssertEqual(before.first?.fitPercent, 86)

        // A debrief that flips yard to "wants less" (D1) re-ranks every home.
        store.applyDebrief(DebriefFixtures.yardTooMuch.draft, home: alder)
        let after = store.ranked(homes)

        XCTAssertFalse(after.first?.home.address.hasPrefix("412 Alder") ?? true,
                       "Alder should fall once the yard becomes a negative")
        XCTAssertTrue(after.first?.home.address.hasPrefix("88 Foundry") ?? false)

        // The profile was revised, and the home is now toured.
        XCTAssertTrue(store.preferences.contains {
            $0.dimension == .yard && $0.direction == .wantsLess
        })
        XCTAssertTrue(store.tourState(of: alder.id).isToured)
        XCTAssertEqual(store.impressions(for: alder.id).count, 1)
    }

    // MARK: ViewModel

    func testSaveCommitsConfirmedPreferencesAndCompletes() async {
        let store = BuyerMemoryStore()
        let alder = FixtureHomesService.demoHomes[0]
        let vm = DebriefViewModel(home: alder,
                                  engine: FixtureDebriefEngine(simulatedDelay: .zero),
                                  buyerMemory: store)

        vm.finishedRecording(transcript: "anything — fixture ignores it")
        for _ in 0..<100 where vm.phase != .confirming { await Task.yield() }

        XCTAssertEqual(vm.phase, .confirming)
        XCTAssertEqual(vm.cards.count, 1)              // the yard contradiction card

        vm.saveTapped()

        XCTAssertEqual(vm.phase, .complete)
        XCTAssertEqual(vm.saved.preferences, 1)
        XCTAssertTrue(store.tourState(of: alder.id).isToured)
        XCTAssertTrue(store.preferences.contains {
            $0.dimension == .yard && $0.direction == .wantsLess
        })
    }

    func testDeselectedPreferenceIsNotCommitted() async {
        let store = BuyerMemoryStore()
        let alder = FixtureHomesService.demoHomes[0]
        let vm = DebriefViewModel(home: alder,
                                  engine: FixtureDebriefEngine(simulatedDelay: .zero),
                                  buyerMemory: store)

        vm.finishedRecording(transcript: "x")
        for _ in 0..<100 where vm.phase != .confirming { await Task.yield() }

        // Toggle the only card off → no profile change should commit.
        vm.toggle(vm.cards[0].id)
        vm.saveTapped()

        XCTAssertEqual(vm.saved.preferences, 0)
        XCTAssertFalse(store.preferences.contains {
            $0.dimension == .yard && $0.direction == .wantsLess
        }, "a toggled-off proposal must not reach memory")
        // But the impression + perceptions still saved (it's still about this home).
        XCTAssertTrue(store.tourState(of: alder.id).isToured)
    }
}
