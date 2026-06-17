//
//  AppDependencyContainer.swift
//  The single dependency container (iOS architecture §6).
//
//  It is the one place that builds screens, so navigation stays decoupled from
//  construction: feature views receive factory *closures*, never the container.
//
//  Phase-1 shell: no live dependencies yet. DataClient, EventLogging,
//  BuyerMemoryStore and the agent engines are added as later PRs land — they
//  become `let` properties here and get injected into the ViewModels.
//

import SwiftUI

@MainActor
final class AppDependencyContainer {
    // MARK: Long-lived dependencies (added in later PRs)
    // let dataClient: DataClient
    // let eventLogger: EventLogging
    // let buyerMemoryStore: BuyerMemoryStore
    // let agentEngines: AgentEngines

    init() {}

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
        // Navigation decoupling: Today knows how to *present* a debrief without
        // knowing how one is built.
        TodayView(makeDebriefView: { self.makeDebriefView() })
    }

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
