//
//  OnboardingView.swift
//  Dumb renderer — talks to its ViewModel only via `send` (iOS architecture §1).
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onComplete: onComplete))
    }

    var body: some View {
        PlaceholderScreen(
            symbol: "mic.circle.fill",
            title: Strings.Onboarding.title,
            message: Strings.Onboarding.message,
            actionTitle: Strings.Onboarding.cta,
            action: { viewModel.send(.finishTapped) }
        )
        .onAppear { viewModel.send(.appeared) }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
