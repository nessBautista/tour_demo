//
//  PrimaryButtonStyle.swift
//  tourDemoApp — UI/Components
//
//  The one branded button style, using design tokens.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.bodyLarge.weight(.semibold))
            .foregroundStyle(AppColor.onAccent)
            .padding(.vertical, Spacing.m)
            .padding(.horizontal, Spacing.xl)
            .background(AppColor.brandPrimary, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview {
    Button("Get started") {}
        .buttonStyle(PrimaryButtonStyle())
        .padding()
        .background(AppColor.appBackground)
}
