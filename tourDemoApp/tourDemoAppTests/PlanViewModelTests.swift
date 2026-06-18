//
//  PlanViewModelTests.swift
//  tourDemoAppTests
//
//  The Plan tab derives grounded next-best-actions from real data, and taking one
//  fires its funnel event into the shared event store (the only "booking" there is).
//  Plain objects, deterministic fixtures (iOS architecture §8).
//

import XCTest
import EventLog
@testable import tourDemoApp

@MainActor
final class PlanViewModelTests: XCTestCase {

    private func makeViewModel(_ store: BuyerMemoryStore) -> (PlanViewModel, InMemoryEventSink) {
        let sink = InMemoryEventSink()
        let vm = PlanViewModel(homesProvider: FixtureHomesService(),
                               eventLogger: EventLogger(sink: sink),
                               buyerMemory: store,
                               eventStore: sink)
        return (vm, sink)
    }

    func testSingleTouredHomeGetsTheSecondLookNorthStar() {
        let store = BuyerMemoryStore()
        let alder = FixtureHomesService.demoHomes[0]
        store.applyDebrief(DebriefFixtures.yardTooMuch.draft, home: alder)

        let (vm, _) = makeViewModel(store)
        vm.send(.homesLoaded(.success(FixtureHomesService.demoHomes)))

        guard let leader = vm.state.actions.first else { return XCTFail("expected actions") }
        XCTAssertEqual(leader.kind, .secondLook)
        XCTAssertTrue(leader.isNorthStar)
        XCTAssertEqual(leader.homeID, alder.id)
        // An untoured home should also yield a "tour" action.
        XCTAssertTrue(vm.state.actions.contains { $0.kind == .tour })
    }

    func testClearWinnerAmongTouredHomesGetsAnOffer() {
        let store = BuyerMemoryStore()
        store.applyDebrief(DebriefFixtures.yardTooMuch.draft, home: FixtureHomesService.demoHomes[0]) // Alder
        store.applyDebrief(DebriefFixtures.loftBright.draft, home: FixtureHomesService.demoHomes[1])   // Foundry

        let (vm, _) = makeViewModel(store)
        vm.send(.homesLoaded(.success(FixtureHomesService.demoHomes)))

        // Foundry leads with a clear gap → an offer, not a second look.
        XCTAssertTrue(vm.state.actions.contains { $0.kind == .offer })
        XCTAssertFalse(vm.state.actions.contains { $0.kind == .secondLook })
    }

    func testTakingAnActionFiresTheFunnelEventAndConfirms() {
        let store = BuyerMemoryStore()
        store.applyDebrief(DebriefFixtures.yardTooMuch.draft, home: FixtureHomesService.demoHomes[0])

        let (vm, sink) = makeViewModel(store)
        vm.send(.homesLoaded(.success(FixtureHomesService.demoHomes)))
        let action = vm.state.actions.first { $0.kind == .secondLook }!

        vm.send(.take(action))

        XCTAssertTrue(vm.state.confirmed.contains(action.key))
        XCTAssertTrue(sink.events.contains { $0.name == "plan.second_look_requested" })
        // The activity feed shows it, starred as the north star.
        XCTAssertTrue(vm.state.activity.contains { $0.isNorthStar })
        // Taking it again is a no-op (one event, not two).
        vm.send(.take(action))
        XCTAssertEqual(sink.events.filter { $0.name == "plan.second_look_requested" }.count, 1)
    }

    func testOpenQuestionBecomesAnAskAgentAction() {
        let store = BuyerMemoryStore()
        store.applyDebrief(DebriefFixtures.loftBright.draft, home: FixtureHomesService.demoHomes[1]) // has an open question

        let (vm, _) = makeViewModel(store)
        vm.send(.homesLoaded(.success(FixtureHomesService.demoHomes)))

        XCTAssertTrue(vm.state.actions.contains { $0.kind == .askAgent })
    }

    func testNothingTouredYetJustSuggestsTouring() {
        let (vm, _) = makeViewModel(BuyerMemoryStore())
        vm.send(.homesLoaded(.success(FixtureHomesService.demoHomes)))

        // No leader / rule-out / ask-agent yet — only "tour the best-fitting home".
        XCTAssertEqual(vm.state.actions.map(\.kind), [.tour])
    }

    func testNoHomesAtAllFallsBackToTheNudge() {
        let (vm, _) = makeViewModel(BuyerMemoryStore())
        vm.send(.homesLoaded(.success([])))

        XCTAssertEqual(vm.state.actions.map(\.kind), [.nudge])
    }
}
