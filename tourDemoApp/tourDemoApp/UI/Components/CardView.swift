//
//  CardView.swift
//  tourDemoApp — UI/Components
//
//  A token-styled surface container. Generic and feature-agnostic; feature
//  screens compose it (iOS architecture §3.2).
//

import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .fill(AppColor.surface)
            )
    }
}

#Preview {
    CardView {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Card title").font(Typography.title)
            Text("Supporting copy").font(Typography.subhead).foregroundStyle(AppColor.textSecondary)
        }
    }
    .padding()
    .background(AppColor.appBackground)
}
