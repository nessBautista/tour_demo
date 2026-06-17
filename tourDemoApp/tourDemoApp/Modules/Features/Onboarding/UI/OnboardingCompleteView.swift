//
//  OnboardingCompleteView.swift
//  tourDemoApp — Modules/Features/Onboarding/UI
//
//  Onboarding screen 5 (design: onBoarding05): the "Profile initialized" confirm.
//  The dark header stays; a short sheet confirms what was saved and offers entry
//  to the app. "Enter the app" reports via a closure (the root scope switch).
//

import SwiftUI

struct OnboardingCompleteView: View {
    var savedCount: Int
    var onEnter: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.surfaceDark.ignoresSafeArea()

            VStack {
                FocusHeader(eyebrow: Strings.Onboarding.eyebrow, title: Strings.Onboarding.title)
                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            sheet
        }
    }

    private var sheet: some View {
        BottomSheet {
            WaveformIcon(color: AppColor.brandPrimary,
                         barWidth: 3, barHeights: [9, 17, 22, 14, 8], spacing: 2.5)

            Text("Profile initialized")
                .font(Typography.heading)
                .foregroundStyle(AppColor.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                statusRow(symbol: "checkmark", size: 12,
                          "\(savedCount) preference\(savedCount == 1 ? "" : "s") saved to your profile")
                statusRow(symbol: "circle.fill", size: 9,
                          "Everything stays editable — the system asks before it commits")
            }

            enterButton
        }
    }

    private func statusRow(symbol: String, size: CGFloat, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
                .frame(width: 16, alignment: .center)
                .padding(.top, 3)
            Text(text)
                .font(Typography.bodyLarge)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var enterButton: some View {
        Button(action: onEnter) {
            Text("Enter the app")
                .font(Typography.bodyLarge.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    AppColor.surface,
                    in: RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                        .stroke(AppColor.divider, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 4)
    }
}

#Preview {
    OnboardingCompleteView(savedCount: 4, onEnter: {})
}
