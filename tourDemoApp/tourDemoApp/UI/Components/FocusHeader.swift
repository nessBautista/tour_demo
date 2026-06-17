//
//  FocusHeader.swift
//  tourDemoApp — UI/Components
//
//  The eyebrow + serif title at the top of the dark "focus" screens (onboarding
//  voice capture, debrief). Parameterized so any flow supplies its own labels.
//

import SwiftUI

struct FocusHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(Typography.eyebrow)
                .tracking(1.5)
                .foregroundStyle(AppColor.brandPrimary)
            Text(title)
                .font(Typography.heading)
                .foregroundStyle(AppColor.onSurfaceDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FocusHeader(eyebrow: "ONBOARDING · VOICE PREFERENCES", title: "Tell me what you’re looking for.")
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.surfaceDark)
}
