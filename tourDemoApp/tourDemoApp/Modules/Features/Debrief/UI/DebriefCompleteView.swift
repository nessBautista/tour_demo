//
//  DebriefCompleteView.swift
//  tourDemoApp — Modules/Features/Debrief/UI
//
//  The debrief's closing screen. Confirms what was saved to this home, then offers
//  the next step the whole loop builds toward: see how the impression moved the
//  ranking (jumps to Compare) — or just finish.
//

import SwiftUI

struct DebriefCompleteView: View {
    let homeName: String
    let saved: DebriefViewModel.SavedSummary
    var onSeeCompare: () -> Void
    var onDone: () -> Void

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
            WaveformIcon(color: AppColor.brandPrimary,
                         barWidth: 3, barHeights: [9, 17, 22, 14, 8], spacing: 2.5)

            Text("\(Strings.Debrief.savedTitle) · \(homeName)")
                .font(Typography.heading)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                let impressionCount = saved.positives + saved.concerns
                if impressionCount > 0 {
                    statusRow(symbol: "checkmark",
                              "\(impressionCount) impression detail\(impressionCount == 1 ? "" : "s") saved to this home")
                }
                if saved.perceptions > 0 {
                    statusRow(symbol: "checkmark",
                              "\(saved.perceptions) home rating\(saved.perceptions == 1 ? "" : "s") adjusted from what you saw")
                }
                if saved.preferences > 0 {
                    statusRow(symbol: "arrow.triangle.2.circlepath",
                              "\(saved.preferences) preference\(saved.preferences == 1 ? "" : "s") updated in your profile — every home re-ranked")
                } else {
                    statusRow(symbol: "circle.fill", size: 9,
                              "Your profile is unchanged — this stayed about this home")
                }
            }

            seeCompareButton
            doneButton
        }
    }

    private func statusRow(symbol: String, size: CGFloat = 12, _ text: String) -> some View {
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

    private var seeCompareButton: some View {
        Button(action: onSeeCompare) {
            Text(Strings.Debrief.seeCompare)
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

    private var doneButton: some View {
        Button(action: onDone) {
            Text(Strings.Debrief.done)
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
    }
}

#Preview {
    DebriefCompleteView(
        homeName: "Alder Court",
        saved: .init(preferences: 1, perceptions: 2, positives: 2, concerns: 1),
        onSeeCompare: {},
        onDone: {}
    )
}
