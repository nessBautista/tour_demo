//  OpenRouterReasoner.swift
//  AgentKit
//
//  The production LLM boundary — OpenRouter's chat/completions, tool-calling
//  path. One client reaches many models (Claude / Gemini / GPT) behind one key.
//  Wire lessons carried over verbatim from the EXP-001 probe (proven live):
//   - key/model trimming (scheme env vars carry stray whitespace),
//   - `max_tokens` (canonical) not `max_completion_tokens`,
//   - `provider.require_parameters: true` against silent capability degradation,
//   - temperature 0,
//   - finish_reason=="error" → one retry, then throw (never a silent end),
//   - reasoning-param 404 on non-reasoning models → retry without it.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking   // Linux: URLSession lives here.
#endif

public enum OpenRouterError: Error, CustomStringConvertible, Equatable {
    case network(String)
    case noHTTPResponse
    case http(status: Int, body: String)
    case malformedContent(String)
    /// 200 envelope but finish_reason=="error": the upstream provider failed
    /// mid-generation. Retried once; thrown if it repeats.
    case providerError(String)

    public var description: String {
        switch self {
        case .network(let m):          return "network error: \(m)"
        case .noHTTPResponse:          return "no HTTP response"
        case .http(let s, let b):      return "HTTP \(s): \(b)"
        case .malformedContent(let m): return "malformed response: \(m)"
        case .providerError(let m):    return "provider error (finish_reason=error): \(m)"
        }
    }
}

/// Per-call telemetry: wall latency plus the usage block OpenRouter returns in
/// every completion envelope. Bridge it to an event/metrics sink for cost.
public struct CallStats: Sendable, Equatable {
    public let model: String
    public let latencyMS: Int
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?
    public let finishReason: String?
    public let toolCallCount: Int

    public init(model: String, latencyMS: Int, promptTokens: Int?, completionTokens: Int?,
                totalTokens: Int?, finishReason: String?, toolCallCount: Int) {
        self.model = model
        self.latencyMS = latencyMS
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.finishReason = finishReason
        self.toolCallCount = toolCallCount
    }

    public var summary: String {
        let tokens = [
            promptTokens.map { "prompt \($0)" },
            completionTokens.map { "completion \($0)" },
            totalTokens.map { "total \($0)" },
        ].compactMap(\.self).joined(separator: " · ")
        return "\(latencyMS) ms · \(tokens.isEmpty ? "usage n/a" : tokens) tok"
            + " · finish=\(finishReason ?? "n/a") · \(toolCallCount) tool call(s) · \(model)"
    }
}

public struct OpenRouterReasoner: Reasoner {
    static let chatURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    let apiKey: String
    let model: String
    let maxCompletionTokens: Int
    let session: URLSession
    let onStats: (@Sendable (CallStats) -> Void)?
    /// nil = provider default; false = send `reasoning: {enabled: false}` (the
    /// cheap/fast extraction setting — hidden thinking tokens drive latency).
    let reasoningEnabled: Bool?

    public init(
        apiKey: String,
        model: String = "anthropic/claude-haiku-4.5",   // dotted slug; tool-calls route reliably
        maxCompletionTokens: Int = 4096,
        session: URLSession = .shared,
        reasoningEnabled: Bool? = nil,
        onStats: (@Sendable (CallStats) -> Void)? = nil
    ) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        self.maxCompletionTokens = maxCompletionTokens
        self.session = session
        self.reasoningEnabled = reasoningEnabled
        self.onStats = onStats
    }

    public func decide(messages: [AgentMessage], tools: [ToolSchema]) async throws -> Decision {
        do {
            return try await decideOnce(messages: messages, tools: tools, reasoning: reasoningEnabled)
        } catch let error as OpenRouterError {
            switch error {
            case .providerError:
                // Transient provider-side generation failure — one retry.
                return try await decideOnce(messages: messages, tools: tools, reasoning: reasoningEnabled)
            case .http(let status, _) where status == 404 && reasoningEnabled != nil:
                // Non-reasoning models have no endpoint supporting the `reasoning`
                // param, and require_parameters turns that into a routing 404.
                // Retry without the reasoning block.
                return try await decideOnce(messages: messages, tools: tools, reasoning: nil)
            default:
                throw error
            }
        }
    }

    private func decideOnce(
        messages: [AgentMessage], tools: [ToolSchema], reasoning: Bool?
    ) async throws -> Decision {
        let body = Self.requestBody(
            model: model, messages: messages, tools: tools,
            maxCompletionTokens: maxCompletionTokens, reasoningEnabled: reasoning)

        var request = URLRequest(url: Self.chatURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let started = Date()
        let reply = try await perform(request)
        let latencyMS = Int(Date().timeIntervalSince(started) * 1000)

        guard reply.status == 200 else {
            throw OpenRouterError.http(
                status: reply.status,
                body: String(data: reply.body, encoding: .utf8) ?? "<non-utf8 \(reply.body.count) bytes>")
        }
        let parsed = try Self.parse(from: reply.body)
        onStats?(CallStats(
            model: model,
            latencyMS: latencyMS,
            promptTokens: parsed.promptTokens,
            completionTokens: parsed.completionTokens,
            totalTokens: parsed.totalTokens,
            finishReason: parsed.finishReason,
            toolCallCount: parsed.decision.toolCalls.count))

        if parsed.finishReason == "error" {
            if let detail = parsed.providerErrorDetail {
                throw OpenRouterError.providerError(detail)
            }
            let raw = String(data: reply.body, encoding: .utf8) ?? "<non-utf8 body>"
            throw OpenRouterError.providerError("no error detail; raw envelope: \(raw.prefix(800))")
        }
        return parsed.decision
    }

    // MARK: Pure request building (unit-tested)

    static func requestBody(
        model: String, messages: [AgentMessage], tools: [ToolSchema],
        maxCompletionTokens: Int, reasoningEnabled: Bool? = nil
    ) -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "temperature": 0,
            "max_tokens": maxCompletionTokens,
            "messages": messages.map(wireMessage(_:)),
            "tools": tools.map(wireTool(_:)),
            "tool_choice": "auto",
            "provider": ["require_parameters": true],
        ]
        if let reasoningEnabled {
            body["reasoning"] = ["enabled": reasoningEnabled]
        }
        return body
    }

    /// Typed message → OpenAI wire dict. The assistant echo reconstructs the exact
    /// tool_calls shape so tool results stay anchored to their calls.
    static func wireMessage(_ message: AgentMessage) -> [String: Any] {
        switch message {
        case .system(let text): return ["role": "system", "content": text]
        case .user(let text):   return ["role": "user", "content": text]
        case .assistant(let decision):
            var dict: [String: Any] = ["role": "assistant", "content": decision.thought ?? ""]
            if !decision.toolCalls.isEmpty {
                dict["tool_calls"] = decision.toolCalls.map { call in
                    ["id": call.id, "type": "function",
                     "function": ["name": call.name, "arguments": call.arguments]] as [String: Any]
                }
            }
            return dict
        case .toolResult(let callID, let content):
            return ["role": "tool", "tool_call_id": callID, "content": content]
        }
    }

    static func wireTool(_ tool: ToolSchema) -> [String: Any] {
        let parameters = (try? JSONSerialization.jsonObject(
            with: Data(tool.parametersJSON.utf8))) as? [String: Any] ?? [:]
        return ["type": "function",
                "function": ["name": tool.name, "description": tool.description,
                             "parameters": parameters]]
    }

    // MARK: Pure decoding (unit-tested)

    struct ParsedResponse {
        let decision: Decision
        let finishReason: String?
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?
        /// Provider error detail OpenRouter attaches to a failed generation
        /// (`choices[0].error` or top-level `error`) — the reason behind
        /// finish_reason=="error" (e.g. a safety block).
        let providerErrorDetail: String?
    }

    /// Parse the completion envelope: `choices[0].message` → a Decision (content =
    /// thought, tool_calls = actions), plus usage + finish_reason for telemetry.
    static func parse(from data: Data) throws -> ParsedResponse {
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any]
        else {
            throw OpenRouterError.malformedContent("could not parse response envelope")
        }

        var calls: [ToolCall] = []
        if let toolCalls = message["tool_calls"] as? [[String: Any]] {
            for tc in toolCalls {
                guard let id = tc["id"] as? String,
                      let fn = tc["function"] as? [String: Any],
                      let name = fn["name"] as? String,
                      let args = fn["arguments"] as? String
                else { continue }
                calls.append(ToolCall(id: id, name: name, arguments: args))
            }
        }
        let content = message["content"] as? String
        let usage = obj["usage"] as? [String: Any]

        var errorDetail: String?
        for candidate in [first["error"], obj["error"]] {
            if let err = candidate as? [String: Any] {
                let code = (err["code"] as? Int).map { " (code \($0))" } ?? ""
                let metadata = (err["metadata"] as? [String: Any]).map { " metadata: \($0)" } ?? ""
                errorDetail = "\(err["message"] as? String ?? "\(err)")\(code)\(metadata)"
                break
            }
        }

        return ParsedResponse(
            decision: Decision(thought: (content?.isEmpty == true) ? nil : content, toolCalls: calls),
            finishReason: first["finish_reason"] as? String,
            promptTokens: usage?["prompt_tokens"] as? Int,
            completionTokens: usage?["completion_tokens"] as? Int,
            totalTokens: usage?["total_tokens"] as? Int,
            providerErrorDetail: errorDetail)
    }

    // MARK: HTTP (I/O — exercised live, not unit-tested)

    private struct HTTPReply: Sendable {
        let status: Int
        let body: Data
    }

    private func perform(_ request: URLRequest) async throws -> HTTPReply {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<HTTPReply, Error>) in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    cont.resume(throwing: OpenRouterError.network(error.localizedDescription)); return
                }
                guard let http = response as? HTTPURLResponse else {
                    cont.resume(throwing: OpenRouterError.noHTTPResponse); return
                }
                cont.resume(returning: HTTPReply(status: http.statusCode, body: data ?? Data()))
            }
            task.resume()
        }
    }
}
