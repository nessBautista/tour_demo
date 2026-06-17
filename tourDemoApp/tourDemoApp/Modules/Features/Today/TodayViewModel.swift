//
//  TodayViewModel.swift
//  tourDemoApp — Modules/Features/Today
//
//  State-Driven MVVM for the Today listings (iOS architecture §1/§4). Fetches
//  homes through the injected `HomesProviding` seam — never Supabase directly.
//  Trigger → Effect → Feedback: `.appeared` launches a Task, and the result
//  re-enters through `send` as `.homesLoaded(...)` — no post-await mutation (§1).
//

import Foundation
import Combine

struct TodayState {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var phase: Phase = .loading
    var homes: [Home] = []
}

enum TodayAction {
    case appeared
    case retryTapped
    case homesLoaded(Result<[Home], Error>)
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var state = TodayState()

    private let homesProvider: any HomesProviding
    private var isLoading = false

    init(homesProvider: any HomesProviding) {
        self.homesProvider = homesProvider
    }

    func send(_ action: TodayAction) {
        switch action {
        case .appeared:
            // Pull-based: load once; the tab re-appearing won't refetch existing data.
            if state.homes.isEmpty { load() }

        case .retryTapped:
            state.phase = .loading
            load()

        case .homesLoaded(let result):
            isLoading = false
            switch result {
            case .success(let homes):
                state.homes = homes
                state.phase = .loaded
                devLog("today: loaded \(homes.count) listings")
            case .failure(let error):
                state.phase = .failed(error.localizedDescription)
                devLog("today: load failed — \(error.localizedDescription)", level: .error)
            }
        }
    }

    // MARK: Effect

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
