//
//  DebriefConfirmView.swift
//  tourDemoApp — Modules/Features/Debrief/UI
//
//  The debrief confirmation step. Shows the impression (positives / concerns as
//  chips) and, below, any proposed CHANGES TO YOUR PROFILE as toggleable cards —
//  the human-in-the-loop. "Save" commits the kept set; an impression with no
//  profile changes is still valid (it records perceptions for this home).
//

import SwiftUI

struct DebriefConfirmView: View {
    let homeName: String
    let draft: DebriefDraft
    let cards: [DebriefViewModel.PrefCard]
    var onToggle: (DebriefViewModel.PrefCard.ID) -> Void
    var onSave: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.surfaceDark.ignoresSafeArea()

            VStack {
                FocusHeader(eyebrow: Strings.Debrief.confirmEyebrow, title: Strings.Debrief.recordTitle)
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
            Text("\(Strings.Debrief.confirmTitle)")
                .font(Typography.heading)
                .foregroundStyle(AppColor.textPrimary)
            Text(Strings.Debrief.confirmSubtitle)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textMuted)

            impressionChips

            if !cards.isEmpty {
                Text(Strings.Debrief.profileChangesHeader)
                    .font(Typography.eyebrow)
                    .tracking(1.5)
                    .foregroundStyle(AppColor.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                VStack(spacing: 10) {
                    ForEach(cards) { card in
                        PreferenceCardRow(proposal: card.proposal, isOn: card.isOn,
                                          onToggle: { onToggle(card.id) })
                    }
                }
            }

            saveButton

            Text(Strings.Debrief.footer)
                .font(Typography.monoSmall)
                .foregroundStyle(AppColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private var impressionChips: some View {
        let chips = draft.positives.map { ($0, true) } + draft.concerns.map { ($0, false) }
        if !chips.isEmpty {
            FlowChips(items: chips)
                .padding(.top, 2)
        }
    }

    private var saveButton: some View {
        Button(action: onSave) {
            Text("Save to \(homeName)")
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
    }
}

// MARK: - Chips

/// Positive (green) / concern (red) impression chips, wrapped to the width.
private struct FlowChips: View {
    /// (text, isPositive)
    let items: [(String, Bool)]

    var body: some View {
        // A simple wrapping layout via `WrapLayout` (iOS 16+ Layout).
        WrapLayout(spacing: 8, lineSpacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                chip(text: item.0, isPositive: item.1)
            }
        }
    }

    private func chip(text: String, isPositive: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: isPositive ? "plus" : "minus")
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(Typography.subhead.weight(.medium))
                .lineLimit(4)
        }
        .foregroundStyle(isPositive ? AppColor.success : AppColor.negative)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isPositive ? AppColor.successTint : AppColor.negativeTint, in: Capsule())
    }
}

/// Minimal flow (wrap) layout — places subviews left-to-right, wrapping to a new
/// line when the row is full. Lane-1 stand-in for a proper chip layout.
private struct WrapLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let intrinsic = subview.sizeThatFits(.unspecified)
            let width = min(intrinsic.width, maxWidth)   // a too-long chip can't exceed the row
            // Re-measure height at the clamped width so a wrapped (2-line) chip reserves its true height.
            let height = subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            if rowWidth + width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + lineSpacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += width + spacing
            rowHeight = max(rowHeight, height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let intrinsic = subview.sizeThatFits(.unspecified)
            let width = min(intrinsic.width, bounds.width)   // clamp so the chip wraps instead of overflowing
            let height = subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            if x + width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: height))
            x += width + spacing
            rowHeight = max(rowHeight, height)
        }
    }
}

#Preview {
    DebriefConfirmView(
        homeName: "Alder Court",
        draft: DebriefFixtures.yardTooMuch.draft,
        cards: DebriefFixtures.yardTooMuch.draft.preferenceUpdates.map { .init(proposal: $0) },
        onToggle: { _ in },
        onSave: {}
    )
}
