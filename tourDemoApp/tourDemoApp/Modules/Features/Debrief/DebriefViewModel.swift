//
//  DebriefViewModel.swift
//  Debrief feature — State / Action / ViewModel (iOS architecture §4).
//
//  Shell stage: a pushed placeholder. The per-home impression stream, recording
//  phases and confirmation cards arrive with feat/per-home-debrief.
//

import Combine
import Foundation

struct DebriefState {
    enum Phase { case idle }   // recording / transcribing / extracting / confirming later
    var phase: Phase = .idle
}

enum DebriefAction {
    case appeared
}

@MainActor
final class DebriefViewModel: ObservableObject {
    @Published private(set) var state = DebriefState()

    func send(_ action: DebriefAction) {
        switch action {
        case .appeared:
            break
        }
    }
}
