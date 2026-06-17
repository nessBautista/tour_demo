//
//  RootViewModel.swift
//  Root scope switch — onboarding ↔ main tabs (iOS architecture §6).
//
//  State-Driven MVVM: View dispatches an Action → `send` reduces it → new State.
//

import Combine
import Foundation

enum RootScope: Equatable {
    case onboarding
    case main
}

enum RootAction {
    case onboardingCompleted
    case resetDemo
}

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var state: RootScope

    /// Phase 1: scope is in-memory and starts at onboarding so the demo walks the
    /// whole flow. Phase 2 seeds it from "buyer memory initialized?" (a DataClient
    /// existence check) — see iOS architecture §6.
    init(scope: RootScope = .onboarding) {
        self.state = scope
    }

    func send(_ action: RootAction) {
        switch action {
        case .onboardingCompleted:
            state = .main
        case .resetDemo:
            state = .onboarding
        }
    }
}
