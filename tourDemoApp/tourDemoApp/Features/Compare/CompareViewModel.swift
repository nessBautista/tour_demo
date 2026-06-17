//
//  CompareViewModel.swift
//  Compare feature — State / Action / ViewModel (iOS architecture §4).
//
//  Shell stage: empty. The ranked, explained ordering (FitScorer + the gather→emit
//  agent rendering RenderBlocks) arrives in Phase 2/3.
//

import Combine
import Foundation

struct CompareState {
    enum Phase { case empty }
    var phase: Phase = .empty
}

enum CompareAction {
    case appeared
}

@MainActor
final class CompareViewModel: ObservableObject {
    @Published private(set) var state = CompareState()

    func send(_ action: CompareAction) {
        switch action {
        case .appeared:
            break
        }
    }
}
