//  Reasoner.swift
//  AgentKit
//
//  The LLM boundary — the one seam between the kernel and a model. The kernel
//  drives the loop against this protocol, so it unit-tests with a scripted stub
//  reasoner and zero network. `OpenRouterReasoner` is the production conformer.

/// Produces the next `Decision` from the conversation so far + the tool palette.
public protocol Reasoner: Sendable {
    func decide(messages: [AgentMessage], tools: [ToolSchema]) async throws -> Decision
}
