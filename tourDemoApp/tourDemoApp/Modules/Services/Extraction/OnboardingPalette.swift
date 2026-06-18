//
//  OnboardingPalette.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The onboarding emit-tools palette: tool schemas + prompts + a pure `apply`
//  dispatcher that builds an `OnboardingDraft`. The agent calls `add_preference`
//  once per stated preference, then `done`. Unlike the probe's free-string
//  aspects, our `dimension` is constrained to the closed `HomeDimension` vocabulary
//  the scorer understands — tighter grounding, deterministic scoring.
//
//  Pure (no I/O, no network) so it unit-tests directly with a scripted ToolCall.
//

import Foundation
import AgentKit
import ComparisonCore

enum OnboardingPalette {

    /// The scorable dimensions the agent may name (budget/note are excluded — they
    /// aren't directly scored as preferences).
    static let dimensions = ["yard", "commute", "quiet", "kitchen", "light", "parking"]

    static var tools: [ToolSchema] { [
        ToolSchema(
            name: "add_preference",
            description: "Record ONE preference the buyer stated about a home. Call once per distinct preference.",
            parametersJSON: """
            {"type":"object","properties":{
              "dimension":{"type":"string","enum":["yard","commute","quiet","kitchen","light","parking"],"description":"The trait, from this fixed set."},
              "direction":{"type":"string","enum":["more","less"],"description":"more = wants MORE of the trait (bigger yard, shorter commute, quieter, brighter); less = wants less of it."},
              "importance":{"type":"string","enum":["low","medium","high"],"description":"high = must-have / emphatic; medium = nice-to-have; low = minor."},
              "title":{"type":"string","description":"Short card title, e.g. 'A real yard' or 'A short commute'."},
              "quote":{"type":"string","description":"The buyer's own words, briefly."}
            },"required":["dimension","direction","importance","title","quote"]}
            """),
        ToolSchema(
            name: "done",
            description: "Finish with a ONE-sentence summary of what this buyer is looking for.",
            parametersJSON: """
            {"type":"object","properties":{"summary":{"type":"string"}},"required":["summary"]}
            """),
    ] }

    static let systemPrompt = """
    You extract a home buyer's preferences from their first voice memo describing \
    what they are looking for. You work by CALLING TOOLS — one add_preference call \
    per distinct preference, then done.

    Rules:
    - Ground every preference strictly in what the buyer said — never invent.
    - One distinct preference per add_preference call.
    - `dimension` must be one of: yard, commute, quiet, kitchen, light, parking.
      Map the buyer's words onto the closest one (e.g. "near work" → commute,
      "lots of windows" → light, "somewhere peaceful" → quiet).
    - `direction` is "more" when they want more of the trait as named (a bigger
      yard, a SHORTER commute → more, quieter → more), "less" when they want less.
    - importance: high only when the buyer is emphatic ("non-negotiable", "must");
      otherwise medium, or low for an offhand mention.
    - Always finish by calling done with a one-sentence summary.
    """

    static func userPrompt(transcript: String) -> String {
        """
        Buyer's voice memo:
        \(transcript)

        Extract the preferences by calling the tools, then call done.
        """
    }

    // MARK: Dispatch (pure)

    private struct PreferenceArgs: Decodable {
        let dimension: String
        let direction: String
        let importance: String
        let title: String
        let quote: String
    }
    private struct DoneArgs: Decodable { let summary: String }

    static func apply(_ call: ToolCall, _ draft: inout OnboardingDraft) -> DispatchResult {
        let data = Data(call.arguments.utf8)
        switch call.name {
        case "add_preference":
            guard let args = try? JSONDecoder().decode(PreferenceArgs.self, from: data),
                  let dimension = HomeDimension(rawValue: args.dimension),
                  let direction = Self.direction(args.direction),
                  let importance = Self.importance(args.importance)
            else {
                return DispatchResult(observation: "error: invalid add_preference arguments", isDone: false)
            }
            let kind: PreferenceProposal.Kind = importance == .high ? .mustHave : .niceToHave
            draft.preferences.append(PreferenceProposal(
                kind: kind, title: args.title, quote: args.quote,
                dimension: dimension, direction: direction, importance: importance))
            return DispatchResult(observation: "ok", isDone: false)

        case "done":
            if let args = try? JSONDecoder().decode(DoneArgs.self, from: data) { draft.summary = args.summary }
            return DispatchResult(observation: "ok", isDone: true)

        default:
            return DispatchResult(observation: "error: unknown tool '\(call.name)'", isDone: false)
        }
    }

    static func direction(_ raw: String) -> Direction? {
        switch raw {
        case "more": .wantsMore
        case "less": .wantsLess
        default:     nil
        }
    }

    static func importance(_ raw: String) -> Importance? {
        switch raw {
        case "low":    .low
        case "medium": .medium
        case "high":   .high
        default:       nil
        }
    }
}
