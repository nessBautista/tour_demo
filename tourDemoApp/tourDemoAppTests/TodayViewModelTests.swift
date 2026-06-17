//
//  TodayViewModelTests.swift
//  tourDemoAppTests
//
//  The pattern's core testability claim (iOS architecture §8): a ViewModel is a
//  plain object — send an Action, assert the State. Today now ranks listings by
//  fit against the buyer profile, so the reducer tests assert the ranking too.
//

import XCTest
@testable import tourDemoApp

@MainActor
final class TodayViewModelTests: XCTestCase {

    // MARK: Reducer (deterministic, no effect)

    func testHomesLoadedRanksByFitBestFirst() {
        // Default buyer profile (yard + quiet high, commute + kitchen medium) over
        // the fixture ratings → Alder wins, fits descending.
        let vm = TodayViewModel(homesProvider: FixtureHomesService())

        vm.send(.homesLoaded(.success(FixtureHomesService.demoHomes)))

        XCTAssertEqual(vm.state.phase, .loaded)
        XCTAssertEqual(vm.state.scored.count, 3)
        XCTAssertTrue(vm.state.scored.first?.home.address.hasPrefix("412 Alder") ?? false)
        XCTAssertEqual(vm.state.scored.first?.fitPercent, 86)
        let fits = vm.state.scored.map(\.fit)
        XCTAssertEqual(fits, fits.sorted(by: >))
    }

    func testHomesLoadedFailureSurfacesErrorState() {
        let vm = TodayViewModel(homesProvider: FixtureHomesService())

        vm.send(.homesLoaded(.failure(HomesError.invalidResponse)))

        XCTAssertTrue(vm.state.scored.isEmpty)
        guard case .failed(let message) = vm.state.phase else {
            return XCTFail("expected .failed, got \(vm.state.phase)")
        }
        XCTAssertFalse(message.isEmpty)
    }

    // MARK: Effect (drives the injected provider seam)

    func testAppearedLoadsAndRanksThroughTheProvider() async {
        let fixture = FixtureHomesService()
        let vm = TodayViewModel(homesProvider: fixture)

        vm.send(.appeared)
        // The effect runs in a Task; yield until it reports back (fixture is fast).
        for _ in 0..<100 where vm.state.phase == .loading {
            await Task.yield()
        }

        XCTAssertEqual(vm.state.phase, .loaded)
        XCTAssertEqual(vm.state.scored.count, fixture.homes.count)
    }
}
