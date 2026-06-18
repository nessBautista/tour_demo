//  Schemas.swift
//  AgentKit
//
//  The ReAct vocabulary, adapted to the emit-tools profile: the model's action
//  space IS the tool palette (bounded JSON tool calls), but the concepts stay
//  first-class — thought, action, observation, trajectory, decision.
//
//  Value types only, no I/O — so they compile and unit-test on Linux with
//  nothing to mock. The JSON/wire mapping lives in the reasoner, not here.

// MARK: - Actions (tool calls)

/// One tool invocation emitted by the model. `arguments` is the raw JSON string
/// exactly as the wire carries it (OpenAI/OpenRouter encode function args as a
/// JSON *string*); a palette decodes it into its typed DTOs.
public struct ToolCall: Sendable, Equatable {
    public let id: String
    public let name: String
    public let arguments: String

    public init(id: String, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

/// A tool's wire schema (OpenAI/OpenRouter `tools` entry). `parametersJSON` holds
/// the JSON-Schema object as a string so this type stays Sendable + Equatable;
/// the reasoner parses it when building the request body.
public struct ToolSchema: Sendable, Equatable {
    public let name: String
    public let description: String
    public let parametersJSON: String

    public init(name: String, description: String, parametersJSON: String) {
        self.name = name
        self.description = description
        self.parametersJSON = parametersJSON
    }
}

// MARK: - Reasoning output

/// The result of one reasoning cycle. Under tool calling the model may attach a
/// free-text thought (message `content`) and several actions (tool calls) per turn.
public struct Decision: Sendable, Equatable {
    public let thought: String?
    public let toolCalls: [ToolCall]

    public init(thought: String?, toolCalls: [ToolCall]) {
        self.thought = thought
        self.toolCalls = toolCalls
    }
}

// MARK: - Trajectory

/// One trajectory entry: a thought affects nothing; an action reaches the
/// dispatcher; an observation is what came back (a tool result, or a recoverable
/// error string the model can read and correct on the next turn).
public enum Step: Sendable, Equatable {
    case thought(String)
    case action(ToolCall)
    case observation(String)
}

/// Trajectory rendering — for debugging and an in-app "show the loop" view.
public enum Trajectory {
    public static func line(for step: Step) -> String {
        switch step {
        case .thought(let text):     return "Thought: \(text)"
        case .action(let call):      return "Action: \(call.name)(\(call.arguments))"
        case .observation(let text): return "Observation: \(text)"
        }
    }

    public static func render(_ steps: [Step]) -> String {
        steps.map(line(for:)).joined(separator: "\n")
    }
}

// MARK: - Conversation

/// A typed chat message for the tool loop. Typing it (rather than untyped dicts)
/// keeps the stub reasoner and the tests honest; the reasoner maps it to the wire.
public enum AgentMessage: Sendable, Equatable {
    case system(String)
    case user(String)
    case assistant(Decision)
    case toolResult(callID: String, content: String)
}
