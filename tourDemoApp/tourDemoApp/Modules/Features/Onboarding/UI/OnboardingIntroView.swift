//
//  OnboardingIntroView.swift
//  tourDemoApp — Modules/Features/Onboarding/UI
//
//  First onboarding screen (design: onBoarding01): the invitation to record. Pure
//  presentation — renders the prompt and reports the single intent (tap to start)
//  via a closure.
//

import SwiftUI

struct OnboardingIntroView: View {
    var onStartTapped: () -> Void

    private let title = Strings.Onboarding.title
    private let message = "Thirty seconds, out loud — the way you’d tell a friend. "
        + "It becomes a profile you confirm and correct, and it sharpens with every home you tour."

    var body: some View {
        ZStack {
            AppColor.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(title)
                        .font(Typography.display)
                        .tracking(-0.3)
                        .lineSpacing(5)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(message)
                        .font(Typography.bodyLarge)
                        .lineSpacing(7)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: Spacing.xl)

                VStack(spacing: 18) {
                    RecordButton(size: 86, action: onStartTapped)
                    Text("Tap and just talk")
                        .font(Typography.subhead.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: Spacing.xl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

#Preview {
    OnboardingIntroView(onStartTapped: {})
}
