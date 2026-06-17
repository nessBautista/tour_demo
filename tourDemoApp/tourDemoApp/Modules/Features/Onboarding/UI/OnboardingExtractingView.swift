//
//  OnboardingExtractingView.swift
//  tourDemoApp — Modules/Features/Onboarding/UI
//
//  Onboarding screen 3 (design: onBoarding03): the extraction state. UX only — the
//  emit-tools outline reveals one canned line at a time while the ViewModel runs
//  the real extraction; the VM advances to the profile phase when the draft
//  returns. (The live agent loop replaces these with real EmitEvents in Phase 3.)
//

import SwiftUI

struct OnboardingExtractingView: View {
    private let calls = [
        "add_must_have( … )",
        "add_must_have( … )",
        "add_nice_to_have( … )",
        "add_nice_to_have( … )",
        "done()",
    ]

    @State private var shown = 0

    var body: some View {
        ZStack {
            AppColor.surfaceDark.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                FocusHeader(eyebrow: Strings.Onboarding.eyebrow, title: Strings.Onboarding.title)

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

                footer
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .task { await reveal() }
    }

    private func reveal() async {
        for step in 1...calls.count {
            try? await Task.sleep(for: .milliseconds(480))
            shown = step
        }
    }

    private var footer: some View {
        Text("on-device transcript → emit-tools\n"
             + "each call becomes a card you confirm — nothing commits silently")
            .font(Typography.monoSmall)
            .foregroundStyle(AppColor.onSurfaceDarkMuted)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
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
    OnboardingExtractingView()
}
