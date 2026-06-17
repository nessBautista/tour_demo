//
//  AppRouter.swift
//  tourDemoApp — App
//
//  The one bit of cross-tab navigation state: which main tab is selected, plus the
//  home a debrief just touched (so Compare can highlight it). Lives at the app root
//  (owned by the container, bound by MainTabView) so a flow inside one tab — the
//  debrief, pushed on Today — can hand the buyer to another (Compare) on completion.
//  Kept tiny on purpose; model-driven navigation, no global singletons (§6).
//

import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable { case today, compare, plan }

    @Published var selectedTab: Tab = .today
    /// The most recently debriefed home — Compare flags it as "updated".
    @Published private(set) var focusHomeID: UUID?

    /// Jump to Compare, optionally focusing the home just debriefed.
    func goToCompare(focus: UUID?) {
        focusHomeID = focus
        selectedTab = .compare
    }
}
