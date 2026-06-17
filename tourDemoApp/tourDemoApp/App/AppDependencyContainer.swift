//
//  AppDependencyContainer.swift
//  The single dependency container (iOS architecture §6).
//
//  It is the one place that builds screens, so navigation stays decoupled from
//  construction: feature views receive factory *closures*, never the container.
//
//  Long-lived dependencies are assembled here once at launch and injected into
//  ViewModels as protocols. EventLogging, BuyerMemoryStore and the agent engines
//  arrive in later PRs.
//

import SwiftUI

@MainActor
final class AppDependencyContainer {
    // MARK: Long-lived dependencies
    /// Listings source — live Supabase when keys are set, fixtures otherwise (§6).
    let homesProvider: any HomesProviding
    // let eventLogger: EventLogging
    // let buyerMemoryStore: BuyerMemoryStore
    // let agentEngines: AgentEngines

    init() {
        self.homesProvider = HomesServiceFactory.make()
    }

    // MARK: Composition roots
    // RootView / MainTabView are the app's own scaffolding, so they may take the
    // container. Feature screens below get closures only.

    func makeRootView() -> RootView {
        RootView(container: self)
    }

    func makeMainTabView() -> MainTabView {
        MainTabView(container: self)
    }

    // MARK: Feature factories

    func makeOnboardingView(onComplete: @escaping () -> Void) -> OnboardingView {
        OnboardingView(onComplete: onComplete)
    }

    func makeTodayView() -> TodayView {
        TodayView(homesProvider: homesProvider)
    }

    // Reached from Today once feat/per-home-debrief wires it up.
    func makeDebriefView() -> DebriefView {
        DebriefView()
    }

    func makeCompareView() -> CompareView {
        CompareView()
    }

    func makePlanView() -> PlanView {
        PlanView()
    }
}
