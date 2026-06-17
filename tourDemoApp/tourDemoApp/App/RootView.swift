//
//  RootView.swift
//  Swaps the entire root on scope change — no stacked navigation into onboarding
//  (iOS architecture §1, rule 6 / §6 scope switching).
//

import SwiftUI

struct RootView: View {
    let container: AppDependencyContainer
    @StateObject private var viewModel = RootViewModel()

    init(container: AppDependencyContainer) {
        self.container = container
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .onboarding:
                container.makeOnboardingView(
                    onComplete: { viewModel.send(.onboardingCompleted) }
                )
            case .main:
                container.makeMainTabView()
            }
        }
        .onAppear {
            #if DEBUG
            // The shake-triggered Developer Tools read the app's shared event store
            // and fire the demo reset. Wire both from the container once.
            DevTools.shared.onResetDemo = { viewModel.send(.resetDemo) }
            DevTools.shared.eventStore = container.eventStore
            #endif
        }
    }
}
