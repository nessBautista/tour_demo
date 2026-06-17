//
//  RecordButton.swift
//  tourDemoApp — UI/Components
//
//  Circular accent record control: brand fill + the brand drop shadow. Waveform
//  glyph when idle, a stop square while recording. Reports taps via a closure.
//

import SwiftUI

struct RecordButton: View {
    var isRecording: Bool = false
    var size: CGFloat = 72
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(AppColor.brandPrimary)
                if isRecording {
                    RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                        .fill(AppColor.onAccent)
                        .frame(width: size * 0.32, height: size * 0.32)
                } else {
                    WaveformIcon(color: AppColor.onAccent)
                }
            }
            .frame(width: size, height: size)
            .shadow(color: AppColor.brandShadow, radius: 14, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isRecording ? "Finish recording" : "Record")
    }
}

/// Generic press feedback: gently scales the label while pressed.
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 32) {
        RecordButton(size: 86, action: {})
        RecordButton(isRecording: true, size: 64, action: {})
    }
    .padding(40)
    .background(AppColor.surfaceDark)
}
