//
//  AppDependencyContainer.swift
//  The single dependency container (iOS architecture §6).
//
//  It is the one place that builds screens, so navigation stays decoupled from
//  construction: feature views receive factory *closures*, never the container.
//
//  Long-lived dependencies are assembled here once at launch and injected into
//  ViewModels. BuyerMemoryStore and the agent engines arrive in later PRs.
//

import SwiftUI
import EventLog

@MainActor
final class AppDependencyContainer {
    // MARK: Long-lived dependencies
    /// Listings source — live Supabase when keys are set, fixtures otherwise (§6).
    let homesProvider: any HomesProviding
    /// One event system the whole app emits into — built once, injected everywhere.
    /// `store` is where the in-app event/cost view reads from (§7).
    let logging: Logging
    /// The shared buyer profile (§6) — onboarding writes it, Today/Compare rank by it.
    let buyerMemory: BuyerMemoryStore
    /// Which main tab is selected + the last-debriefed home (cross-tab navigation).
    let router = AppRouter()
    // let agentEngines: AgentEngines

    var eventLogger: EventLogger { logging.logger }
    var eventStore: InMemoryEventSink { logging.store }

    init() {
        self.homesProvider = HomesServiceFactory.make()
        self.logging = LoggingFactory.make()
        self.buyerMemory = BuyerMemoryStore()
    }

    // MARK: Composition roots
    // RootView / MainTabView are the app's own scaffolding, so they may take the
    // container. Feature screens below get closures only.

    func makeRootView() -> RootView {
        RootView(container: self)
    }

    func makeMainTabView() -> MainTabView {
        MainTabView(container: self, router: router)
    }

    // MARK: Feature factories

    func makeOnboardingView(onComplete: @escaping () -> Void) -> OnboardingView {
        OnboardingView(onComplete: onComplete, eventLogger: eventLogger, buyerMemory: buyerMemory)
    }

    func makeTodayView() -> TodayView {
        TodayView(
            homesProvider: homesProvider,
            eventLogger: eventLogger,
            buyerMemory: buyerMemory,
            debrief: { [self] home, onClose, onSeeCompare in
                makeDebriefView(home: home, onClose: onClose, onSeeCompare: onSeeCompare)
            },
            goToCompare: { [router] id in router.goToCompare(focus: id) }
        )
    }

    /// The per-home debrief flow, pushed onto Today's stack.
    func makeDebriefView(home: Home,
                         onClose: @escaping () -> Void = {},
                         onSeeCompare: @escaping () -> Void = {}) -> DebriefView {
        DebriefView(home: home,
                    eventLogger: eventLogger,
                    buyerMemory: buyerMemory,
                    onClose: onClose,
                    onSeeCompare: onSeeCompare)
    }

    func makeCompareView() -> CompareView {
        CompareView(homesProvider: homesProvider,
                    eventLogger: eventLogger,
                    buyerMemory: buyerMemory,
                    currentFocus: { [router] in router.focusHomeID },
                    memory: { [self] in makeBuyerMemoryView() })
    }

    /// The buyer-memory panel, pushed from Compare.
    func makeBuyerMemoryView() -> BuyerMemoryView {
        BuyerMemoryView(buyerMemory: buyerMemory, eventLogger: eventLogger)
    }

    func makePlanView() -> PlanView {
        PlanView(homesProvider: homesProvider,
                 eventLogger: eventLogger,
                 buyerMemory: buyerMemory,
                 eventStore: eventStore)
    }
}
