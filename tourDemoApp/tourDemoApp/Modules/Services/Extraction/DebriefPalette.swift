//
//  DebriefPalette.swift
//  tourDemoApp — Modules/Services/Extraction
//
//  The debrief emit-tools palette: a post-tour impression → a structured draft.
//
//  A like/dislike is recorded with ONE call: `add_positive` / `add_concern` carry
//  the buyer's words (the human-facing chip) AND an optional `dimension`. When the
//  dimension is set, the same call also nudges THIS home's perceived rating
//  (positive → better, concern → worse). Keeping it one tool — rather than a
//  separate "rate this home" tool — is what stops the model routing everything
//  through ratings and leaving the impression empty (observed live, 2026).
//
//  `propose_preference_update` is the only GLOBAL effect: a change to the buyer's
//  profile (re-ranks every home), flagged with `contradicts_current` when it
//  reverses an earlier stance. Pure dispatch — unit-testable with scripted calls.
//

import Foundation
import AgentKit
import ComparisonCore

enum DebriefPalette {

    static var tools: [ToolSchema] { [
        ToolSchema(
            name: "add_positive",
            description: "Something the buyer LIKED about this home. Set `dimension` when it's about a scored trait (it then also raises this home's rating on that trait).",
            parametersJSON: """
            {"type":"object","properties":{
              "text":{"type":"string","description":"The buyer's words, briefly."},
              "dimension":{"type":"string","enum":["yard","commute","quiet","kitchen","light","parking"],"description":"OPTIONAL — the scored trait this is about; omit for a general remark."}
            },"required":["text"]}
            """),
        ToolSchema(
            name: "add_concern",
            description: "Something the buyer was WORRIED about with this home. Set `dimension` when it's about a scored trait (it then also lowers this home's rating on that trait).",
            parametersJSON: """
            {"type":"object","properties":{
              "text":{"type":"string","description":"The buyer's words, briefly."},
              "dimension":{"type":"string","enum":["yard","commute","quiet","kitchen","light","parking"],"description":"OPTIONAL — the scored trait this is about; omit for a general remark."}
            },"required":["text"]}
            """),
        ToolSchema(
            name: "add_open_question",
            description: "A follow-up the buyer wants answered (e.g. 'how old is the roof?').",
            parametersJSON: """
            {"type":"object","properties":{"text":{"type":"string"}},"required":["text"]}
            """),
        ToolSchema(
            name: "propose_preference_update",
            description: "Propose a change to the buyer's GLOBAL profile (affects all homes). Use only when the buyer revises what they want IN GENERAL, not just about this home.",
            parametersJSON: """
            {"type":"object","properties":{
              "dimension":{"type":"string","enum":["yard","commute","quiet","kitchen","light","parking"]},
              "direction":{"type":"string","enum":["more","less"]},
              "importance":{"type":"string","enum":["low","medium","high"]},
              "title":{"type":"string","description":"Short card title, e.g. 'Less yard to keep up'."},
              "quote":{"type":"string","description":"The buyer's own words, briefly."},
              "contradicts_current":{"type":"boolean","description":"true if this revises a preference they stated earlier (e.g. wanted a big yard, now wants less)."}
            },"required":["dimension","direction","importance","title","quote","contradicts_current"]}
            """),
        ToolSchema(
            name: "done",
            description: "Finish with a ONE-sentence summary of the impression.",
            parametersJSON: """
            {"type":"object","properties":{"summary":{"type":"string"}},"required":["summary"]}
            """),
    ] }

    static let systemPrompt = """
    You extract a home buyer's impression from a short voice debrief recorded right \
    after touring ONE specific home. You work by CALLING TOOLS, then done.

    Tools:
    - add_positive / add_concern: EVERY like or worry the buyer expresses, in their
      words. Attach a `dimension` (yard, commute, quiet, kitchen, light, parking)
      whenever the remark is about one of those scored traits — that one call then
      both records the impression AND adjusts this home's rating. Omit `dimension`
      for general remarks (e.g. "loved the character", "felt cramped").
    - add_open_question: a follow-up they want answered.
    - propose_preference_update: the buyer revised what they want IN GENERAL (their
      global profile) — set direction "more"/"less", importance, and
      contradicts_current = true when it reverses an earlier stance ("I said a big
      yard was a must, but…"). Use this sparingly — most debriefs are about this
      home, not a profile rewrite.

    Rules:
    - Ground everything strictly in what the buyer said — never invent.
    - Capture the likes and worries with add_positive/add_concern; don't leave the
      impression empty just because something also affected a rating.
    - Always finish by calling done with a one-sentence summary.
    """

    static func userPrompt(transcript: String, homeAddress: String) -> String {
        """
        The buyer just toured: \(homeAddress)

        Their voice debrief:
        \(transcript)

        Extract the impression by calling the tools, then call done.
        """
    }

    // MARK: Dispatch (pure)

    private struct ReactionArgs: Decodable { let text: String; let dimension: String? }
    private struct TextArgs: Decodable { let text: String }
    private struct UpdateArgs: Decodable {
        let dimension: String
        let direction: String
        let importance: String
        let title: String
        let quote: String
        let contradicts_current: Bool
    }
    private struct DoneArgs: Decodable { let summary: String }

    static func apply(_ call: ToolCall, _ draft: inout DebriefDraft) -> DispatchResult {
        let data = Data(call.arguments.utf8)
        switch call.name {
        case "add_positive":
            guard let args = try? JSONDecoder().decode(ReactionArgs.self, from: data) else {
                return DispatchResult(observation: "error: invalid add_positive arguments", isDone: false)
            }
            draft.positives.append(args.text)
            if let dimension = args.dimension.flatMap(HomeDimension.init(rawValue:)) {
                draft.perceptions.append(HomePerception(dimension: dimension, polarity: .better, reason: args.text))
            }
            return DispatchResult(observation: "ok", isDone: false)

        case "add_concern":
            guard let args = try? JSONDecoder().decode(ReactionArgs.self, from: data) else {
                return DispatchResult(observation: "error: invalid add_concern arguments", isDone: false)
            }
            draft.concerns.append(args.text)
            if let dimension = args.dimension.flatMap(HomeDimension.init(rawValue:)) {
                draft.perceptions.append(HomePerception(dimension: dimension, polarity: .worse, reason: args.text))
            }
            return DispatchResult(observation: "ok", isDone: false)

        case "add_open_question":
            guard let args = try? JSONDecoder().decode(TextArgs.self, from: data) else {
                return DispatchResult(observation: "error: invalid add_open_question arguments", isDone: false)
            }
            draft.openQuestions.append(args.text)
            return DispatchResult(observation: "ok", isDone: false)

        case "propose_preference_update":
            guard let args = try? JSONDecoder().decode(UpdateArgs.self, from: data),
                  let dimension = HomeDimension(rawValue: args.dimension),
                  let direction = OnboardingPalette.direction(args.direction),
                  let importance = OnboardingPalette.importance(args.importance)
            else {
                return DispatchResult(observation: "error: invalid propose_preference_update arguments", isDone: false)
            }
            let kind: PreferenceProposal.Kind = args.contradicts_current
                ? .priority
                : (importance == .high ? .mustHave : .niceToHave)
            draft.preferenceUpdates.append(PreferenceProposal(
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
}
