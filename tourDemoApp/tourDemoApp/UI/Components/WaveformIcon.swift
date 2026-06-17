//
//  WaveformIcon.swift
//  tourDemoApp — UI/Components
//
//  The brand's "voice" glyph: a row of rounded vertical bars. Reusable wherever
//  recording/voice appears. All values are parameterizable.
//

import SwiftUI

struct WaveformIcon: View {
    var color: Color = AppColor.onAccent
    var barWidth: CGFloat = 4
    var barHeights: [CGFloat] = [12, 22, 30, 18, 10]
    var spacing: CGFloat = 3

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { _, height in
                Capsule()
                    .fill(color)
                    .frame(width: barWidth, height: height)
            }
        }
    }
}

#Preview {
    WaveformIcon(color: AppColor.brandPrimary)
        .padding()
        .background(AppColor.appBackground)
}
