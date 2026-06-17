//
//  OnboardingProfileView.swift
//  tourDemoApp — Modules/Features/Onboarding/UI
//
//  Onboarding confirmation step (design: onBoarding04). Data-driven: one toggleable
//  card per extracted preference. Toggling off excludes it; "Save profile" commits
//  the kept set — the human-in-the-loop step (nothing reaches memory unconfirmed).
//

import SwiftUI

struct OnboardingProfileView: View {
    let cards: [OnboardingViewModel.ProfileCard]
    var onToggle: (OnboardingViewModel.ProfileCard.ID) -> Void
    var onSave: () -> Void

    private var keptCount: Int { cards.filter(\.isOn).count }

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
            Text("PROFILE · WHAT I’LL REMEMBER")
                .font(Typography.eyebrow)
                .tracking(1.5)
                .foregroundStyle(AppColor.brandPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Here’s your profile.")
                    .font(Typography.heading)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Toggle off anything that’s not you — the rest saves together.")
                    .font(Typography.bodyLarge)
                    .foregroundStyle(AppColor.textMuted)
            }

            VStack(spacing: 10) {
                ForEach(cards) { card in
                    PreferenceCardRow(proposal: card.proposal, isOn: card.isOn,
                                      onToggle: { onToggle(card.id) })
                }
            }
            .padding(.top, 4)

            saveButton

            Text("nothing commits until you save")
                .font(Typography.monoSmall)
                .foregroundStyle(AppColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var saveButton: some View {
        Button(action: onSave) {
            Text("Save profile · \(keptCount) items")
                .font(Typography.bodyLarge.weight(.semibold))
                .foregroundStyle(AppColor.onSurfaceDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    AppColor.textPrimary,
                    in: RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 4)
        .disabled(keptCount == 0)
        .opacity(keptCount == 0 ? 0.5 : 1)
    }
}

#Preview {
    OnboardingProfileView(
        cards: OnboardingFixtures.standard.draft.preferences.map { .init(proposal: $0) },
        onToggle: { _ in },
        onSave: {}
    )
}
