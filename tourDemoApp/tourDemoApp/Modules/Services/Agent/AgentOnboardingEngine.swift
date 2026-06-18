//
//  AgentOnboardingEngine.swift
//  tourDemoApp — Modules/Services/Agent
//
//  The live onboarding extractor: runs the AgentKit EmitLoop over the onboarding
//  palette and returns the same `OnboardingDraft` the fixture engine does — so it
//  drops in behind the `OnboardingExtracting` seam with nothing downstream changing
//  (the confirmation cards, BuyerMemoryStore, and scoring are all unchanged).
//

import Foundation
import AgentKit
import EventLog

struct AgentOnboardingEngine: OnboardingExtracting {
    let reasoner: any Reasoner
    let events: EventLogger
    var maxTurns: Int

    init(reasoner: any Reasoner,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         maxTurns: Int = 4) {
        self.reasoner = reasoner
        self.events = eventLogger
        self.maxTurns = maxTurns
    }

    func extract(transcript: String) async throws -> OnboardingDraft {
        let logger = events
        do {
            let outcome = try await EmitLoop(reasoner: reasoner, maxTurns: maxTurns).run(
                systemPrompt: OnboardingPalette.systemPrompt,
                userPrompt: OnboardingPalette.userPrompt(transcript: transcript),
                tools: OnboardingPalette.tools,
                initialOutput: OnboardingDraft(),
                apply: { call, draft in OnboardingPalette.apply(call, &draft) },
                onEvent: { event in logAgentEvent(event, feature: "onboarding", logger: logger) })
            devLog("onboarding: agent finished — \(outcome.output.preferences.count) preference(s)"
                   + " (loop \(outcome.finished ? "completed" : "hit turn budget"))")
            return outcome.output
        } catch {
            devLog("onboarding: agent error — \(error)", level: .error)
            throw error
        }
    }
}
