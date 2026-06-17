//
//  BottomSheet.swift
//  tourDemoApp — UI/Components
//
//  A generic bottom-sheet surface: leading-aligned content with standard padding,
//  on a top-rounded panel that bleeds into the bottom safe area. Feature-agnostic
//  chrome — the onboarding profile / complete sheets compose it and supply their
//  own content.
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            content()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radius.xxl, topTrailingRadius: Radius.xxl,
                                   style: .continuous)
                .fill(AppColor.appBackground)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppColor.surfaceDark.ignoresSafeArea()
        BottomSheet {
            Text("Sheet title").font(Typography.heading).foregroundStyle(AppColor.textPrimary)
            Text("Some supporting content.").font(Typography.bodyLarge).foregroundStyle(AppColor.textSecondary)
        }
    }
}
