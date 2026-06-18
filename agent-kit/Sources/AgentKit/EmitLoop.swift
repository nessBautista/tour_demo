//  EmitLoop.swift
//  AgentKit
//
//  The kernel: a single-pass emit-tools loop, generic over the Output it builds.
//  One iteration = one reasoner call; each returned tool call is dispatched
//  through the palette's `apply`, and its result (ok / recoverable error) is fed
//  back as an observation. The message echo IS the ReAct re-feeding — the model
//  sees its own calls + results on the next turn.
//
//  Generic over `Output` so every feature brings its own draft type, tools, and
//  `apply`. `apply` is async: pure "emit" tools dispatch synchronously, while
//  "read" tools (a gather→emit profile) can perform real I/O and return their
//  observation. Both profiles are this one kernel — only the palette differs.
//
//  A stub reasoner makes the whole loop testable with zero network.

/// The result of dispatching one tool call.
public struct DispatchResult: Sendable, Equatable {
    /// The tool_result content fed back to the model ("ok" or "error: …").
    public let observation: String
    /// True when the palette's terminal tool (`done`) fired.
    public let isDone: Bool

    public init(observation: String, isDone: Bool) {
        self.observation = observation
        self.isDone = isDone
    }
}

/// Loop telemetry, emitted live as the loop runs — drive a console trace or an
/// in-app "show reasoning" view, and bridge it to an event/metrics sink.
public enum EmitEvent: Sendable {
    case thought(turn: Int, String)
    case action(turn: Int, ToolCall)
    case observation(turn: Int, String)
}

public struct EmitLoop: Sendable {
    let reasoner: any Reasoner
    let maxTurns: Int

    public init(reasoner: any Reasoner, maxTurns: Int = 4) {
        self.reasoner = reasoner
        self.maxTurns = maxTurns
    }

    /// The loop's result: the built output, the full trajectory, and whether the
    /// terminal `done` fired (`false` = the turn budget was spent first — a real
    /// outcome the caller decides how to present).
    public struct Outcome<Output: Sendable>: Sendable {
        public let output: Output
        public let trajectory: [Step]
        public let finished: Bool

        public init(output: Output, trajectory: [Step], finished: Bool) {
            self.output = output
            self.trajectory = trajectory
            self.finished = finished
        }
    }

    /// Run to completion. `apply` is the palette's dispatcher: it mutates the
    /// draft `output` and reports the observation + whether `done` fired.
    public func run<Output: Sendable>(
        systemPrompt: String,
        userPrompt: String,
        tools: [ToolSchema],
        initialOutput: Output,
        apply: @Sendable (ToolCall, inout Output) async -> DispatchResult,
        onEvent: (@Sendable (EmitEvent) -> Void)? = nil
    ) async throws -> Outcome<Output> {
        var messages: [AgentMessage] = [.system(systemPrompt), .user(userPrompt)]
        var output = initialOutput
        var trajectory: [Step] = []
        var finished = false

        var turn = 0
        while turn < maxTurns && !finished {
            turn += 1
            let decision = try await reasoner.decide(messages: messages, tools: tools)
            messages.append(.assistant(decision))

            if let thought = decision.thought, !thought.isEmpty {
                trajectory.append(.thought(thought))
                onEvent?(.thought(turn: turn, thought))
            }

            // Model stopped calling tools without `done` — a real outcome the
            // caller decides how to present (the budget-spent analog).
            if decision.toolCalls.isEmpty { break }

            for call in decision.toolCalls {
                trajectory.append(.action(call))
                onEvent?(.action(turn: turn, call))

                let result = await apply(call, &output)
                trajectory.append(.observation(result.observation))
                onEvent?(.observation(turn: turn, result.observation))
                messages.append(.toolResult(callID: call.id, content: result.observation))

                if result.isDone { finished = true }
            }
        }

        return Outcome(output: output, trajectory: trajectory, finished: finished)
    }
}
