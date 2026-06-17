//
//  DebriefExtractingView.swift
//  tourDemoApp — Modules/Features/Debrief/UI
//
//  The extraction state of a debrief — UX only. The emit-tools outline reveals one
//  canned call at a time while the ViewModel runs the real extraction; the VM
//  advances to the confirm phase when the draft returns. Mirrors the onboarding
//  extracting screen with the debrief tool palette (add_positive / add_concern /
//  propose_preference_update / done). The live agent replaces these in Phase 3.
//

import SwiftUI

struct DebriefExtractingView: View {
    private let calls = [
        "add_positive( … )",
        "add_concern( … )",
        "propose_preference_update( … )",
        "done()",
    ]

    @State private var shown = 0

    var body: some View {
        ZStack {
            AppColor.surfaceDark.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                FocusHeader(eyebrow: Strings.Debrief.eyebrow, title: Strings.Debrief.recordTitle)

                Text("Got it. Pulling out what mattered…")
                    .font(Typography.serifBody)
                    .foregroundStyle(AppColor.onSurfaceDark)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(calls.enumerated()), id: \.offset) { index, call in
                        if index < shown {
                            ToolCallRow(text: call)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shown)

                Spacer(minLength: 0)

                Text("on-device transcript → emit-tools\n"
                     + "positives and concerns describe this home — profile changes become cards you confirm")
                    .font(Typography.monoSmall)
                    .foregroundStyle(AppColor.onSurfaceDarkMuted)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .task { await reveal() }
    }

    private func reveal() async {
        for step in 1...calls.count {
            try? await Task.sleep(for: .milliseconds(440))
            shown = step
        }
    }
}

private struct ToolCallRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.fill")
                .font(.system(size: 9))
                .foregroundStyle(AppColor.brandPrimary)
            Text(text)
                .font(Typography.mono)
                .foregroundStyle(AppColor.onSurfaceDark)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.success)
        }
    }
}

#Preview {
    DebriefExtractingView()
}
