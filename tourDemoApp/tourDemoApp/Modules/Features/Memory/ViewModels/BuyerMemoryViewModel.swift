//
//  BuyerMemoryViewModel.swift
//  tourDemoApp — Modules/Features/Memory/ViewModels
//
//  State-Driven MVVM for the buyer-memory panel (iOS architecture §4). Pull-based:
//  it snapshots the BuyerMemoryStore on appear and after each action, since the
//  store isn't observable (§6). It surfaces the profile, the recurrence-driven
//  promote suggestions, contradictions, and the per-home impression stream — and
//  commits a promotion only when the buyer accepts it (the human-in-the-loop gate).
//

import Foundation
import Combine
import EventLog
import ComparisonCore

@MainActor
final class BuyerMemoryViewModel: ObservableObject {
    struct Snapshot: Equatable {
        var preferences: [Preference] = []
        var suggestions: [PromoteSuggestion] = []
        var contradictions: [Contradiction] = []
        /// All saved impressions, newest first, across every home.
        var impressions: [Impression] = []
        var debriefedHomes: Int = 0
    }

    @Published private(set) var snapshot = Snapshot()

    private let buyerMemory: BuyerMemoryStore
    private let events: EventLogger
    /// Suggestions the buyer waved off this session — kept out of the list.
    private var dismissed: Set<HomeDimension> = []

    init(buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink())) {
        self.buyerMemory = buyerMemory
        self.events = eventLogger
    }

    // MARK: Intents

    func appeared() {
        refresh()
        events.log("memory.opened",
                   properties: ["profile": buyerMemory.summary,
                                "suggestions": String(snapshot.suggestions.count),
                                "debriefed": String(snapshot.debriefedHomes)])
    }

    func promote(_ suggestion: PromoteSuggestion) {
        buyerMemory.promote(suggestion)
        events.log("memory.promoted",
                   properties: ["dimension": suggestion.dimension.rawValue,
                                "importance": String(suggestion.proposedImportance.weight),
                                "added": String(suggestion.isNew)])
        devLog("memory: promoted \(suggestion.dimension.rawValue) → "
               + "weight \(suggestion.proposedImportance.weight) · new profile [\(buyerMemory.summary)]")
        refresh()
    }

    func dismiss(_ suggestion: PromoteSuggestion) {
        dismissed.insert(suggestion.dimension)
        events.log("memory.promote_dismissed",
                   properties: ["dimension": suggestion.dimension.rawValue])
        refresh()
    }

    // MARK: Effect

    private func refresh() {
        snapshot = Snapshot(
            preferences: buyerMemory.preferences,
            suggestions: buyerMemory.promoteSuggestions().filter { !dismissed.contains($0.dimension) },
            contradictions: buyerMemory.contradictions,
            impressions: buyerMemory.impressions.values.flatMap { $0 }
                .sorted { $0.recordedAt > $1.recordedAt },
            debriefedHomes: buyerMemory.debriefedHomeCount
        )
    }
}
