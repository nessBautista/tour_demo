//
//  AgentTrace.swift
//  tourDemoApp — Modules/Services/Agent
//
//  One place to trace an agent run. `devLog` prints a copy-pasteable transcript to
//  the Xcode console (greppable `TD|…`), so a live extraction can be handed off for
//  assessment; the event log keeps the structured tool calls for the in-app Events
//  tab. Called from the loop's `onEvent`, which runs off the main thread — both
//  sinks are safe there (devLog hops its store update to main; EventLog is Sendable).
//

import AgentKit
import EventLog

@Sendable
func logAgentEvent(_ event: EmitEvent, feature: String, logger: EventLogger) {
    switch event {
    case .thought(let turn, let text):
        devLog("\(feature): [t\(turn)] thought — \(text)")
    case .action(let turn, let call):
        devLog("\(feature): [t\(turn)] → \(call.name)(\(call.arguments))")
        logger.log("\(feature).agent_tool", properties: ["tool": call.name])
    case .observation(let turn, let text):
        devLog("\(feature): [t\(turn)] ↳ \(text)")
    }
}
