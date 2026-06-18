//
//  TourStateTests.swift
//  tourDemoAppTests
//
//  The funnel ladder: notToured → booked → debriefed, never backwards, and a booked
//  home becomes Compare-eligible. Plain store calls (iOS architecture §8).
//

import XCTest
@testable import tourDemoApp

@MainActor
final class TourStateTests: XCTestCase {

    func testBookAdvancesNotTouredToBooked() {
        let store = BuyerMemoryStore()
        let home = FixtureHomesService.demoHomes[0]

        XCTAssertEqual(store.tourState(of: home.id), .notToured)
        store.book(home.id)
        XCTAssertEqual(store.tourState(of: home.id), .booked)
        XCTAssertTrue(store.tourState(of: home.id).isToured)
    }

    func testDebriefMovesToDebriefedAndBookingDoesNotRegress() {
        let store = BuyerMemoryStore()
        let home = FixtureHomesService.demoHomes[0]

        store.book(home.id)
        store.applyDebrief(DebriefFixtures.fixture(for: home).draft, home: home)
        XCTAssertEqual(store.tourState(of: home.id), .debriefed)

        // A later "book" (e.g. a second look) must not knock it back to booked.
        store.book(home.id)
        XCTAssertEqual(store.tourState(of: home.id), .debriefed)
    }

    func testBookedHomeIsCompareEligibleWithNoImpressions() {
        let store = BuyerMemoryStore()
        let homes = FixtureHomesService.demoHomes
        store.book(homes[1].id)                       // booked, never debriefed

        let booked = store.ranked(homes).first { $0.home.id == homes[1].id }
        XCTAssertEqual(booked?.tourState, .booked)
        XCTAssertTrue(booked?.isToured ?? false)       // enters Compare on cue
        XCTAssertEqual(booked?.impressionCount, 0)
    }

    func testDebriefedHomeStampsItsImpressionCount() {
        let store = BuyerMemoryStore()
        let alder = FixtureHomesService.demoHomes[0]
        store.applyDebrief(DebriefFixtures.yardTooMuch.draft, home: alder)

        let scored = store.ranked(FixtureHomesService.demoHomes).first { $0.home.id == alder.id }
        XCTAssertEqual(scored?.tourState, .debriefed)
        XCTAssertEqual(scored?.impressionCount, 1)
    }
}
