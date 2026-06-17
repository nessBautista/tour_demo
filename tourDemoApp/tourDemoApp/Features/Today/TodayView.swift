//
//  TodayView.swift
//  Dumb renderer. Owns the tab's NavigationStack; pushes Debrief via the injected
//  factory closure, driven by State.route (iOS architecture §5, §6).
//

import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    private let makeDebriefView: () -> DebriefView

    init(makeDebriefView: @escaping () -> DebriefView) {
        self.makeDebriefView = makeDebriefView
    }

    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                symbol: "house.fill",
                title: Strings.Today.title,
                message: Strings.Today.message,
                actionTitle: Strings.Today.openDebrief,
                action: { viewModel.send(.openDebriefTapped) }
            )
            .navigationTitle(Strings.Tabs.today)
            .navigationDestination(item: routeBinding) { _ in
                makeDebriefView()
            }
            .onAppear { viewModel.send(.appeared) }
        }
    }

    /// Bridges State.route to SwiftUI navigation: reads from State, writes back as
    /// an Action so the loop stays unidirectional.
    private var routeBinding: Binding<TodayState.Route?> {
        Binding(
            get: { viewModel.state.route },
            set: { newValue in if newValue == nil { viewModel.send(.routeDismissed) } }
        )
    }
}

#Preview {
    TodayView(makeDebriefView: { DebriefView() })
}
