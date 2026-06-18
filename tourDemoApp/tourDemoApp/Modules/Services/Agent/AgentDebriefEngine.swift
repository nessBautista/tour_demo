//
//  AgentDebriefEngine.swift
//  tourDemoApp — Modules/Services/Agent
//
//  The live debrief extractor: runs the AgentKit EmitLoop over the debrief palette
//  for one home and returns the same `DebriefDraft` the fixture engine does — so it
//  drops in behind the `DebriefExtracting` seam. The confirmation cards, per-home
//  perceptions, profile updates, and scoring downstream are all unchanged.
//
//  `contradicts_current` is the agent's own judgment from the transcript; the store
//  also flags direction-flips independently, so a missed flag is still caught.
//

import Foundation
import AgentKit
import EventLog

struct AgentDebriefEngine: DebriefExtracting {
    let reasoner: any Reasoner
    let events: EventLogger
    var maxTurns: Int

    init(reasoner: any Reasoner,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         maxTurns: Int = 6) {
        self.reasoner = reasoner
        self.events = eventLogger
        self.maxTurns = maxTurns
    }

    func extract(transcript: String, home: Home) async throws -> DebriefDraft {
        let logger = events
        do {
            let outcome = try await EmitLoop(reasoner: reasoner, maxTurns: maxTurns).run(
                systemPrompt: DebriefPalette.systemPrompt,
                userPrompt: DebriefPalette.userPrompt(transcript: transcript, homeAddress: home.address),
                tools: DebriefPalette.tools,
                initialOutput: DebriefDraft(),
                apply: { call, draft in DebriefPalette.apply(call, &draft) },
                onEvent: { event in logAgentEvent(event, feature: "debrief", logger: logger) })
            let d = outcome.output
            devLog("debrief: agent finished — \(d.positives.count) positive(s), \(d.concerns.count) concern(s), "
                   + "\(d.perceptions.count) perception(s), \(d.preferenceUpdates.count) profile change(s)"
                   + " (loop \(outcome.finished ? "completed" : "hit turn budget"))")
            return outcome.output
        } catch {
            devLog("debrief: agent error — \(error)", level: .error)
            throw error
        }
    }
}
