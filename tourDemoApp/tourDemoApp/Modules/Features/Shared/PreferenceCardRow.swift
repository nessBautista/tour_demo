//
//  PreferenceCardRow.swift
//  tourDemoApp — Modules/Features/Shared
//
//  One toggleable confirmation card for a `PreferenceProposal` — the human-in-the-
//  loop unit shared by onboarding ("here's your profile") and debrief ("changes to
//  your profile"). Lives in Features/Shared, NOT UI, because it renders a Service
//  type (`PreferenceProposal`); UI-tier components may import Core only (§3.2).
//

import SwiftUI

struct PreferenceCardRow: View {
    let proposal: PreferenceProposal
    let isOn: Bool
    var onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                badge
                VStack(alignment: .leading, spacing: 3) {
                    Text(proposal.title)
                        .font(Typography.bodyLarge.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                    Text("“\(proposal.quote)”")
                        .font(Typography.subhead.italic())
                        .foregroundStyle(AppColor.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(get: { isOn }, set: { _ in onToggle() }))
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
        .opacity(isOn ? 1 : 0.5)
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
        case .priority:   (AppColor.onAccent,      AppColor.brandPrimary,  false)
        }
    }
}
