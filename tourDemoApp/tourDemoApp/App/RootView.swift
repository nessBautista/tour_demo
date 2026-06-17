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
            // "Reset demo" lives in the shake-triggered Developer Tools, not in any
            // navigation bar. Register the scope reset so the panel can fire it.
            DevTools.shared.onResetDemo = { viewModel.send(.resetDemo) }
            #endif
        }
    }
}
