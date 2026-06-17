//
//  TodayViewModelTests.swift
//  tourDemoAppTests
//
//  The pattern's core testability claim (iOS architecture §8): a ViewModel is a
//  plain object — send an Action, assert the State. The async effect is tested by
//  sending the feedback action directly (no real I/O), plus one integration test
//  that drives the fixture seam end to end.
//

import XCTest
@testable import tourDemoApp

@MainActor
final class TodayViewModelTests: XCTestCase {

    // MARK: Reducer (deterministic, no effect)

    func testHomesLoadedSuccessPopulatesStateAndMarksLoaded() {
        let vm = TodayViewModel(homesProvider: FixtureHomesService())
        let homes = FixtureHomesService.demoHomes

        vm.send(.homesLoaded(.success(homes)))

        XCTAssertEqual(vm.state.homes, homes)
        XCTAssertEqual(vm.state.phase, .loaded)
    }

    func testHomesLoadedFailureSurfacesErrorState() {
        let vm = TodayViewModel(homesProvider: FixtureHomesService())

        vm.send(.homesLoaded(.failure(HomesError.invalidResponse)))

        XCTAssertTrue(vm.state.homes.isEmpty)
        guard case .failed(let message) = vm.state.phase else {
            return XCTFail("expected .failed, got \(vm.state.phase)")
        }
        XCTAssertFalse(message.isEmpty)
    }

    // MARK: Effect (drives the injected provider seam)

    func testAppearedLoadsHomesThroughTheProvider() async {
        let fixture = FixtureHomesService()
        let vm = TodayViewModel(homesProvider: fixture)

        vm.send(.appeared)
        // The effect runs in a Task; yield until it reports back (fixture is fast).
        for _ in 0..<100 where vm.state.phase == .loading {
            await Task.yield()
        }

        XCTAssertEqual(vm.state.phase, .loaded)
        XCTAssertEqual(vm.state.homes, fixture.homes)
    }
}
