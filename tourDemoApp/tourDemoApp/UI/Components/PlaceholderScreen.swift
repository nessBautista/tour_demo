//
//  PlaceholderScreen.swift
//  tourDemoApp — UI/Components
//
//  The empty-state building block every shell screen renders. Feature-agnostic by
//  design: symbol + title + message + optional CTA, all styled from tokens.
//  Phase-2 screens replace it with real content.
//

import SwiftUI

struct PlaceholderScreen: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(AppColor.brandPrimary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.s) {
                Text(title)
                    .font(Typography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.appBackground)
    }
}

#Preview {
    PlaceholderScreen(
        symbol: "house.fill",
        title: "Your homes",
        message: "Listings and tour status will show here.",
        actionTitle: "Get started",
        action: {}
    )
}
