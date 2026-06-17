//
//  AudioWaveform.swift
//  tourDemoApp — UI/Components
//
//  A horizontal row of thin bars suggesting live audio. Decorative (UX only) — it
//  animates on a continuous timeline rather than reflecting real mic levels.
//  Distinct from WaveformIcon (the 5-bar button glyph).
//

import SwiftUI

struct AudioWaveform: View {
    var color: Color = AppColor.brandPrimary
    var barCount: Int = 44
    var animated: Bool = true

    // A fixed pseudo-random profile so it reads as a waveform, not noise.
    private static let seeds: [CGFloat] = [
        0.30, 0.62, 0.95, 0.48, 0.18, 0.80, 0.38, 0.12, 0.55, 0.90,
        0.33, 0.22, 0.70, 0.45, 0.85, 0.28, 0.60, 0.16, 0.50, 0.75,
    ]

    private func height(bar i: Int, t: Double, max: CGFloat) -> CGFloat {
        let base = Self.seeds[i % Self.seeds.count]
        let wobble = animated ? 0.30 * CGFloat(sin(t * 3.0 + Double(i) * 0.55)) : 0
        return Swift.max(2, Swift.min(max, (base + wobble) * max))
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(paused: !animated)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(alignment: .center, spacing: 3) {
                    ForEach(0..<barCount, id: \.self) { i in
                        Capsule()
                            .fill(color)
                            .frame(width: 3, height: height(bar: i, t: t, max: geo.size.height))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

#Preview {
    AudioWaveform()
        .frame(height: 44)
        .padding()
        .background(AppColor.surfaceDark)
}
