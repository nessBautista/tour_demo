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
                    ProfileCardRow(card: card, onToggle: { onToggle(card.id) })
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

// MARK: - Card row

private struct ProfileCardRow: View {
    let card: OnboardingViewModel.ProfileCard
    var onToggle: () -> Void

    private var proposal: PreferenceProposal { card.proposal }

    var body: some View {
        HStack(spacing: 12) {
            badge
            VStack(alignment: .leading, spacing: 3) {
                Text(proposal.title)
                    .font(Typography.bodyLarge.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text("“\(proposal.quote)”")
                    .font(Typography.subhead.italic())
                    .foregroundStyle(AppColor.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(get: { card.isOn }, set: { _ in onToggle() }))
                .labelsHidden()
                .tint(AppColor.success)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.surface,
                    in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
        .opacity(card.isOn ? 1 : 0.5)
    }

    private var badge: some View {
        let (fg, bg, outlined) = Self.badgeStyle(for: proposal.kind)
        return Text(proposal.kind.badge)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(bg, in: Capsule())
            .overlay { if outlined { Capsule().stroke(AppColor.divider, lineWidth: 1) } }
            .fixedSize()
    }

    static func badgeStyle(for kind: PreferenceProposal.Kind) -> (Color, Color, Bool) {
        switch kind {
        case .mustHave:   (AppColor.appBackground, AppColor.textPrimary,   false)
        case .niceToHave: (AppColor.textSecondary, .clear,                 true)
        case .priority:   (AppColor.textMuted,     AppColor.surfaceSunken, false)
        }
    }
}

#Preview {
    OnboardingProfileView(
        cards: OnboardingFixtures.standard.draft.preferences.map { .init(proposal: $0) },
        onToggle: { _ in },
        onSave: {}
    )
}
