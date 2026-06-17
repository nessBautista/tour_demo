//
//  TodayViewModel.swift
//  tourDemoApp — Modules/Features/Today/ViewModels
//
//  State-Driven MVVM for the Today listings (iOS architecture §1/§4). Fetches
//  homes through the injected `HomesProviding` seam — never Supabase directly.
//  Trigger → Effect → Feedback: `.appeared` launches a Task, and the result
//  re-enters through `send` as `.homesLoaded(...)` — no post-await mutation (§1).
//

import Foundation
import Combine
import EventLog

struct TodayState {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var phase: Phase = .loading
    /// Listings ranked by fit against the buyer profile, best first.
    var scored: [ScoredHome] = []
}

enum TodayAction {
    case appeared
    case retryTapped
    case homesLoaded(Result<[Home], Error>)
    /// Dev affordance: flag a home toured so its debrief entry point appears.
    case markToured(UUID)
    /// A pushed debrief popped back — re-rank to reflect its profile/perception edits.
    case debriefReturned
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var state = TodayState()

    private let homesProvider: any HomesProviding
    private let events: EventLogger
    private let buyerMemory: BuyerMemoryStore
    private var isLoading = false

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore()) {
        self.homesProvider = homesProvider
        self.events = eventLogger
        self.buyerMemory = buyerMemory
    }

    func send(_ action: TodayAction) {
        switch action {
        case .appeared:
            events.log("today.appeared")
            // Pull-based: load once; the tab re-appearing won't refetch existing data.
            if state.scored.isEmpty { load() }

        case .retryTapped:
            events.log("today.retry")
            state.phase = .loading
            load()

        case .homesLoaded(let result):
            isLoading = false
            switch result {
            case .success(let homes):
                // Rank against the current buyer profile (deterministic FitScorer).
                state.scored = buyerMemory.ranked(homes)
                state.phase = .loaded
                let ranking = rankingSummary()
                let profile = buyerMemory.summary
                events.log("today.homes_loaded",
                           properties: ["count": String(homes.count),
                                        "profile": profile,
                                        "ranking": ranking])
                devLog("today: profile [\(profile)] → ranked \(homes.count) by fit — \(ranking)")
            case .failure(let error):
                state.phase = .failed(error.localizedDescription)
                events.log("today.homes_failed", category: .system,
                           properties: ["error": error.localizedDescription])
                devLog("today: load failed — \(error.localizedDescription)", level: .error)
            }

        case .markToured(let id):
            buyerMemory.markToured(id)
            rerank()
            events.log("today.marked_toured", properties: ["home": String(id.uuidString.prefix(8))])
            devLog("today: marked \(id.uuidString.prefix(8)) toured")

        case .debriefReturned:
            // The debrief may have changed the profile and/or this home's perception.
            rerank()
            let ranking = rankingSummary()
            events.log("today.reranked_after_debrief",
                       properties: ["profile": buyerMemory.summary, "ranking": ranking])
            devLog("today: re-ranked after debrief — profile [\(buyerMemory.summary)] → \(ranking)")
        }
    }

    /// Re-score the already-loaded homes against the current memory (no refetch).
    private func rerank() {
        state.scored = buyerMemory.ranked(state.scored.map(\.home))
    }

    // MARK: Effect

    /// Compact "Name fit%" list in ranked order, e.g.
    /// "412 Alder Court 86%, 1735 Bellview Avenue 61%, …" — for the console / event log.
    private func rankingSummary() -> String {
        state.scored.map { scored in
            let name = scored.home.address.split(separator: ",").first
                .map(String.init)?.trimmingCharacters(in: .whitespaces) ?? scored.home.address
            return "\(name) \(scored.fitPercent)%"
        }
        .joined(separator: ", ")
    }

    private func load() {
        guard !isLoading else { return }
        isLoading = true
        let provider = homesProvider
        Task { @MainActor [weak self] in
            do {
                let homes = try await provider.fetchHomes()
                self?.send(.homesLoaded(.success(homes)))
            } catch {
                self?.send(.homesLoaded(.failure(error)))
            }
        }
    }
}
