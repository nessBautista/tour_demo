//
//  ReasonerFactory.swift
//  tourDemoApp — Modules/Services/Agent
//
//  Builds the AgentKit `Reasoner` (the LLM boundary for the on-device extraction
//  agent) from config: a live OpenRouter client when OPENROUTER_API_KEY is set,
//  `nil` otherwise — callers then fall back to the fixture engines, so the app
//  still runs keyless (iOS architecture §6, the same pattern as HomesServiceFactory).
//
//  The key is supplied via the Xcode scheme's environment variables (gitignored),
//  exactly like the Supabase keys:
//    Edit Scheme → Run → Arguments → Environment Variables → OPENROUTER_API_KEY = sk-or-…
//

import Foundation
import AgentKit

enum ReasonerFactory {
    /// The live reasoner when a key is configured, else `nil`.
    ///
    /// - Parameters:
    ///   - environment: the config source (defaults to the process environment).
    ///   - model: an explicit OpenRouter slug; when nil, OPENROUTER_MODEL is used,
    ///     else the default (Claude Opus 4.8). OpenRouter slugs are DOTTED, e.g.
    ///     `anthropic/claude-opus-4.8`, `anthropic/claude-haiku-4.5`.
    ///   - onStats: optional per-call token/latency telemetry — bridge it to the
    ///     event log for the in-app cost rollup.
    static func make(
        _ environment: AppEnvironment = AppEnvironment(),
        model: String? = nil,
        onStats: (@Sendable (CallStats) -> Void)? = nil
    ) -> (any Reasoner)? {
        guard let apiKey = environment.value(for: .openRouterAPIKey) else {
            devLog("agent: OPENROUTER_API_KEY missing → extraction will use fixtures", level: .warn)
            return nil
        }
        // haiku-4.5 is the default: it routes tool-calls reliably on OpenRouter
        // (opus-4.8 404s under require_parameters), it's fast + cheap, and the probe
        // rated it best semantic quality for this extraction. Override via OPENROUTER_MODEL.
        let resolved = model ?? environment.value(for: .openRouterModel) ?? "anthropic/claude-haiku-4.5"
        devLog("agent: live OpenRouter reasoner configured (model \(resolved))")
        return OpenRouterReasoner(apiKey: apiKey, model: resolved, onStats: onStats)
    }
}
