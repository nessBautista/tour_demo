//
//  PlanViewModel.swift
//  Plan feature — State / Action / ViewModel (iOS architecture §4).
//
//  Shell stage: empty. Next-best actions (wired to data + the in-app event log)
//  arrive with feat/plan-tab.
//

import Combine
import Foundation

struct PlanState {
    enum Phase { case empty }
    var phase: Phase = .empty
}

enum PlanAction {
    case appeared
}

@MainActor
final class PlanViewModel: ObservableObject {
    @Published private(set) var state = PlanState()

    func send(_ action: PlanAction) {
        switch action {
        case .appeared:
            break
        }
    }
}
