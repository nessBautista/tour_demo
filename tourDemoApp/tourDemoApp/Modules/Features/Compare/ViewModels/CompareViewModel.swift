//
//  CompareViewModel.swift
//  tourDemoApp — Modules/Features/Compare/ViewModels
//
//  State-Driven MVVM for Compare (iOS architecture §4). The explainable ordering of
//  TOURED homes: it re-ranks against the current buyer memory every time the tab
//  appears, so a debrief's effect shows up immediately. Deterministic — the order
//  and every number come from the ComparisonCore FitScorer (via BuyerMemoryStore),
//  never a model. The gather→emit agent narrator is Phase 3 (agent/compare-aid).
//

import Foundation
import Combine
import EventLog

struct CompareState {
    enum Phase: Equatable { case loading, empty, ranked }
    var phase: Phase = .loading
    /// Toured homes, best fit first.
    var ranked: [ScoredHome] = []
    /// The home a debrief just touched, highlighted in the list.
    var focusHomeID: UUID?
}

enum CompareAction {
    case appeared(focus: UUID?)
    case homesLoaded(Result<[Home], Error>)
}

@MainActor
final class CompareViewModel: ObservableObject {
    @Published private(set) var state = CompareState()

    private let homesProvider: any HomesProviding
    private let events: EventLogger
    private let buyerMemory: BuyerMemoryStore

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore()) {
        self.homesProvider = homesProvider
        self.events = eventLogger
        self.buyerMemory = buyerMemory
    }

    func send(_ action: CompareAction) {
        switch action {
        case .appeared(let focus):
            state.focusHomeID = focus
            // Always reload: the profile/perceptions may have changed since last shown.
            load()

        case .homesLoaded(let result):
            switch result {
            case .success(let homes):
                let toured = buyerMemory.ranked(homes).filter(\.isToured)
                state.ranked = toured
                state.phase = toured.isEmpty ? .empty : .ranked
                let order = toured.map { "\(shortName($0.home.address)) \($0.fitPercent)%" }
                    .joined(separator: ", ")
                events.log("compare.ranked",
                           properties: ["toured": String(toured.count),
                                        "profile": buyerMemory.summary,
                                        "order": order])
                devLog("compare: \(toured.count) toured home(s) ranked — \(order)")
            case .failure(let error):
                state.ranked = []
                state.phase = .empty
                devLog("compare: load failed — \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func load() {
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

/// A home's short name: the text before the first comma (e.g. "412 Alder Court").
func shortName(_ address: String) -> String {
    address.split(separator: ",").first
        .map(String.init)?.trimmingCharacters(in: .whitespaces) ?? address
}
