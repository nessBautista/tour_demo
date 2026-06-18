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
import AgentKit

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
    /// The on-device extraction agent's LLM boundary — a live OpenRouter reasoner
    /// when OPENROUTER_API_KEY is set, else nil (extraction falls back to fixtures).
    /// The extraction engines (PR `agent/react-loop`) inject this behind the
    /// existing OnboardingExtracting / DebriefExtracting seams.
    let reasoner: (any Reasoner)?

    var eventLogger: EventLogger { logging.logger }
    var eventStore: InMemoryEventSink { logging.store }
    /// True when a live agent is available (key configured).
    var hasLiveAgent: Bool { reasoner != nil }

    init() {
        let logging = LoggingFactory.make()
        self.homesProvider = HomesServiceFactory.make()
        self.logging = logging
        self.buyerMemory = BuyerMemoryStore()
        // Bridge each model call's token/latency telemetry into the event log, so
        // the DevTools inference rollup shows real agent cost.
        let inferenceLogger = logging.logger
        self.reasoner = ReasonerFactory.make(onStats: { stats in
            devLog("agent: \(stats.summary)")
            inferenceLogger.inference(
                model: stats.model,
                operation: "extraction",
                inputTokens: stats.promptTokens ?? 0,
                outputTokens: stats.completionTokens ?? 0,
                latencyMS: stats.latencyMS,
                succeeded: stats.finishReason != "error",
                properties: ["finish": stats.finishReason ?? "n/a",
                             "tools": String(stats.toolCallCount)])
        })
    }

    /// The live extraction engines when a reasoner is configured, else nil → the
    /// feature ViewModels fall back to their fixture engines (keyless demo).
    private var onboardingEngine: (any OnboardingExtracting)? {
        reasoner.map { AgentOnboardingEngine(reasoner: $0, eventLogger: eventLogger) }
    }
    private var debriefEngine: (any DebriefExtracting)? {
        reasoner.map { AgentDebriefEngine(reasoner: $0, eventLogger: eventLogger) }
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
        OnboardingView(onComplete: onComplete, engine: onboardingEngine,
                       eventLogger: eventLogger, buyerMemory: buyerMemory)
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
                    engine: debriefEngine,
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
