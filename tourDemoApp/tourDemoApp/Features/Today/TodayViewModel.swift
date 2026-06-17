//
//  TodayViewModel.swift
//  Today feature — State / Action / ViewModel (iOS architecture §4).
//
//  Navigation is model-driven: a `Route` lives inside State; the View binds to it
//  (no boolean-flag soup, no NavigationLink scattering — §1 rule 5).
//

import Combine
import Foundation

struct TodayState {
    enum Route: Hashable, Identifiable {
        case debrief
        var id: Self { self }
    }
    var route: Route?
}

enum TodayAction {
    case appeared
    case openDebriefTapped
    case routeDismissed
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var state = TodayState()

    func send(_ action: TodayAction) {
        switch action {
        case .appeared:
            break
        case .openDebriefTapped:
            state.route = .debrief
        case .routeDismissed:
            state.route = nil
        }
    }
}
