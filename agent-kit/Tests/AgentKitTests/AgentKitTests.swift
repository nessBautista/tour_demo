//  AgentKitTests.swift
//  AgentKitTests
//
//  The kernel is proven here with a scripted stub reasoner and zero network: the
//  EmitLoop drives a tiny example palette to a typed Output, and the reasoner's
//  pure request-building / envelope-parsing are unit-tested directly.

import XCTest
@testable import AgentKit

// MARK: - Scripted reasoner (zero network)

private actor StubReasoner: Reasoner {
    private let decisions: [Decision]
    private var index = 0
    init(_ decisions: [Decision]) { self.decisions = decisions }

    func decide(messages: [AgentMessage], tools: [ToolSchema]) async throws -> Decision {
        defer { index += 1 }
        // Past the script → an empty turn, which ends the loop (budget-spent analog).
        return index < decisions.count ? decisions[index] : Decision(thought: nil, toolCalls: [])
    }
}

// MARK: - A tiny example palette (stands in for a real feature's palette)

private struct Basket: Sendable, Equatable {
    var items: [String] = []
    var summary: String?
}

private struct AddArgs: Decodable { let name: String }
private struct DoneArgs: Decodable { let summary: String }

private let basketTools = [
    ToolSchema(name: "add_item", description: "add one item",
               parametersJSON: #"{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}"#),
    ToolSchema(name: "done", description: "finish with a summary",
               parametersJSON: #"{"type":"object","properties":{"summary":{"type":"string"}},"required":["summary"]}"#),
]

@Sendable private func basketApply(_ call: ToolCall, _ output: inout Basket) async -> DispatchResult {
    let data = Data(call.arguments.utf8)
    switch call.name {
    case "add_item":
        guard let args = try? JSONDecoder().decode(AddArgs.self, from: data) else {
            return DispatchResult(observation: "error: bad add_item arguments", isDone: false)
        }
        output.items.append(args.name)
        return DispatchResult(observation: "ok", isDone: false)
    case "done":
        if let args = try? JSONDecoder().decode(DoneArgs.self, from: data) { output.summary = args.summary }
        return DispatchResult(observation: "ok", isDone: true)
    default:
        return DispatchResult(observation: "error: unknown tool '\(call.name)'", isDone: false)
    }
}

private func call(_ name: String, _ args: String, id: String = "c") -> ToolCall {
    ToolCall(id: id, name: name, arguments: args)
}

// MARK: - EmitLoop

final class EmitLoopTests: XCTestCase {

    func testBuildsOutputAndFinishesOnDone() async throws {
        let reasoner = StubReasoner([
            Decision(thought: "add two things", toolCalls: [
                call("add_item", #"{"name":"yard"}"#, id: "1"),
                call("add_item", #"{"name":"light"}"#, id: "2"),
            ]),
            Decision(thought: nil, toolCalls: [call("done", #"{"summary":"two items"}"#, id: "3")]),
        ])

        let outcome = try await EmitLoop(reasoner: reasoner, maxTurns: 4).run(
            systemPrompt: "s", userPrompt: "u", tools: basketTools,
            initialOutput: Basket(), apply: basketApply)

        XCTAssertTrue(outcome.finished)
        XCTAssertEqual(outcome.output.items, ["yard", "light"])
        XCTAssertEqual(outcome.output.summary, "two items")
        XCTAssertTrue(outcome.trajectory.contains(.thought("add two things")))
        XCTAssertTrue(outcome.trajectory.contains(.observation("ok")))
    }

    func testBudgetSpentWithoutDone() async throws {
        let reasoner = StubReasoner([
            Decision(thought: nil, toolCalls: [call("add_item", #"{"name":"a"}"#)]),
            Decision(thought: nil, toolCalls: [call("add_item", #"{"name":"b"}"#)]),
        ])

        let outcome = try await EmitLoop(reasoner: reasoner, maxTurns: 2).run(
            systemPrompt: "s", userPrompt: "u", tools: basketTools,
            initialOutput: Basket(), apply: basketApply)

        XCTAssertFalse(outcome.finished)            // never called done within budget
        XCTAssertEqual(outcome.output.items, ["a", "b"])
    }

    func testEmptyToolCallsEndsTheLoop() async throws {
        let reasoner = StubReasoner([Decision(thought: "nothing to do", toolCalls: [])])

        let outcome = try await EmitLoop(reasoner: reasoner, maxTurns: 4).run(
            systemPrompt: "s", userPrompt: "u", tools: basketTools,
            initialOutput: Basket(), apply: basketApply)

        XCTAssertFalse(outcome.finished)
        XCTAssertTrue(outcome.output.items.isEmpty)
    }

    func testRecoverableErrorObservationDoesNotCrashAndContinues() async throws {
        let reasoner = StubReasoner([
            Decision(thought: nil, toolCalls: [call("add_item", "not json", id: "1")]),
            Decision(thought: nil, toolCalls: [call("done", #"{"summary":"ok"}"#, id: "2")]),
        ])

        let outcome = try await EmitLoop(reasoner: reasoner, maxTurns: 4).run(
            systemPrompt: "s", userPrompt: "u", tools: basketTools,
            initialOutput: Basket(), apply: basketApply)

        XCTAssertTrue(outcome.finished)
        XCTAssertTrue(outcome.output.items.isEmpty)     // the bad call added nothing
        XCTAssertTrue(outcome.trajectory.contains(.observation("error: bad add_item arguments")))
    }

    func testEventsEmittedInOrder() async throws {
        let reasoner = StubReasoner([
            Decision(thought: "t", toolCalls: [call("done", #"{"summary":"x"}"#)]),
        ])
        final class Box: @unchecked Sendable { var kinds: [String] = [] }
        let box = Box()

        _ = try await EmitLoop(reasoner: reasoner).run(
            systemPrompt: "s", userPrompt: "u", tools: basketTools,
            initialOutput: Basket(), apply: basketApply,
            onEvent: { event in
                switch event {
                case .thought:     box.kinds.append("thought")
                case .action:      box.kinds.append("action")
                case .observation: box.kinds.append("observation")
                }
            })

        XCTAssertEqual(box.kinds, ["thought", "action", "observation"])
    }
}

// MARK: - OpenRouterReasoner (pure halves)

final class OpenRouterReasonerTests: XCTestCase {

    func testRequestBodyShape() {
        let body = OpenRouterReasoner.requestBody(
            model: "anthropic/claude-opus-4.8",
            messages: [.system("s"), .user("u")],
            tools: basketTools, maxCompletionTokens: 4096, reasoningEnabled: false)

        XCTAssertEqual(body["model"] as? String, "anthropic/claude-opus-4.8")
        XCTAssertEqual(body["temperature"] as? Int, 0)
        XCTAssertEqual(body["max_tokens"] as? Int, 4096)
        XCTAssertEqual(body["tool_choice"] as? String, "auto")
        XCTAssertNotNil(body["tools"])
        XCTAssertEqual((body["provider"] as? [String: Any])?["require_parameters"] as? Bool, true)
        XCTAssertEqual((body["reasoning"] as? [String: Any])?["enabled"] as? Bool, false)
    }

    func testRequestBodyOmitsReasoningWhenNil() {
        let body = OpenRouterReasoner.requestBody(
            model: "m", messages: [.user("u")], tools: [], maxCompletionTokens: 100, reasoningEnabled: nil)
        XCTAssertNil(body["reasoning"])
    }

    func testParseDecodesToolCallsThoughtAndUsage() throws {
        let json = #"""
        {"choices":[{"finish_reason":"tool_calls","message":{"content":"thinking","tool_calls":[{"id":"call_1","type":"function","function":{"name":"add_item","arguments":"{\"name\":\"yard\"}"}}]}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
        """#
        let parsed = try OpenRouterReasoner.parse(from: Data(json.utf8))

        XCTAssertEqual(parsed.decision.thought, "thinking")
        XCTAssertEqual(parsed.decision.toolCalls.count, 1)
        XCTAssertEqual(parsed.decision.toolCalls.first?.name, "add_item")
        XCTAssertEqual(parsed.decision.toolCalls.first?.arguments, #"{"name":"yard"}"#)
        XCTAssertEqual(parsed.promptTokens, 10)
        XCTAssertEqual(parsed.totalTokens, 15)
        XCTAssertEqual(parsed.finishReason, "tool_calls")
    }

    func testParseSurfacesProviderErrorDetail() throws {
        let json = #"{"choices":[{"finish_reason":"error","message":{"content":""},"error":{"message":"safety block","code":403}}]}"#
        let parsed = try OpenRouterReasoner.parse(from: Data(json.utf8))

        XCTAssertEqual(parsed.finishReason, "error")
        XCTAssertTrue(parsed.providerErrorDetail?.contains("safety block") ?? false)
    }

    func testParseMalformedEnvelopeThrows() {
        XCTAssertThrowsError(try OpenRouterReasoner.parse(from: Data("not json".utf8)))
    }
}
