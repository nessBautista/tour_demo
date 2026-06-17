//
//  VoiceRecordingView.swift
//  tourDemoApp — Modules/Features/Shared
//
//  A reusable recording component shared by Onboarding (and, later, Debrief). It
//  lives in Features/Shared — NOT UI — because it drives a Service (the voice-
//  extraction package); UI-tier components may import Core only (architecture §3.2).
//
//  The dark recording screen (design: onBoarding02). Drives a `VoiceTranscribing`
//  from the voice-extraction package: on a real iOS 26 device it requests mic +
//  speech permission and captures live; in the Simulator (and the demo video) the
//  FixtureAudioTranscriber plays the bundled clip and streams matching captions.
//  Either way the live transcript streams in, and on stop the finalized text is
//  handed back via onFinish.
//
//  Lives in Features (not UI) because it drives a Service (architecture §3.2).
//

import SwiftUI
import Combine
import VoiceExtraction

struct VoiceRecordingView: View {
    let eyebrow: String
    let title: String
    /// Canonical script — what the fixture streams, and the fallback if live
    /// capture comes back empty.
    let script: String
    var onFinish: (String) -> Void

    @State private var voice: any VoiceTranscribing
    @State private var started = false
    @State private var elapsed = 0
    @State private var cursorOn = true

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let blinker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init(eyebrow: String, title: String, script: String, onFinish: @escaping (String) -> Void) {
        self.eyebrow = eyebrow
        self.title = title
        self.script = script
        self.onFinish = onFinish
        _voice = State(initialValue: OnboardingVoiceFactory.make(script: script))
    }

    var body: some View {
        ZStack {
            AppColor.surfaceDark.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                FocusHeader(eyebrow: eyebrow, title: title)

                AudioWaveform()
                    .frame(height: 40)
                    .padding(.vertical, 4)

                transcriptView

                Spacer(minLength: 0)

                bottomBar
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .task { await begin() }
        .onDisappear { if voice.isRecording { Task { await voice.stopRecording() } } }
        .onReceive(ticker) { _ in elapsed += 1 }
        .onReceive(blinker) { _ in cursorOn.toggle() }
    }

    // MARK: - Lifecycle

    private func begin() async {
        guard !started else { return }
        started = true

        #if os(iOS) && !targetEnvironment(simulator)
        // Real-engine path: the live mic needs both authorizations first.
        let status = await SpeechPermissions.request()
        devLog("voice: permissions — mic \(status.microphone), speech \(status.speechRecognition)")
        #endif

        await voice.prepare()
        await voice.startRecording()
        devLog("voice: started (\(String(describing: type(of: voice))))")
    }

    private func finish() {
        Task {
            await voice.stopRecording()
            let captured = voice.transcript.finalized.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = captured.isEmpty ? script : captured
            devLog("voice: finished · \(captured.count) chars captured\(captured.isEmpty ? " (empty → using script)" : "")")
            onFinish(text)
        }
    }

    // MARK: - Transcript

    private var transcriptView: some View {
        let transcript = voice.transcript
        let hasText = !transcript.isEmpty
        return (
            Text(transcript.finalized).foregroundStyle(AppColor.onSurfaceDark)
            + Text(transcript.volatile).foregroundStyle(AppColor.onSurfaceDarkMuted)
            + Text(hasText ? (cursorOn ? " ▍" : "  ") : (cursorOn ? "Listening… ▍" : "Listening…  "))
                .foregroundStyle(AppColor.brandPrimary)
        )
        .font(Typography.serifBody.italic())
        .lineSpacing(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            Text(timeString)
                .font(Typography.mono)
                .foregroundStyle(AppColor.onSurfaceDarkMuted)
                .frame(width: 64, alignment: .leading)

            Spacer()

            RecordButton(isRecording: true, size: 64, action: finish)

            Spacer()

            Text("tap to\nfinish")
                .font(Typography.monoSmall)
                .foregroundStyle(AppColor.onSurfaceDarkMuted)
                .frame(width: 64, alignment: .leading)
        }
    }

    private var timeString: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }
}

#Preview {
    VoiceRecordingView(
        eyebrow: "ONBOARDING · VOICE PREFERENCES",
        title: "Tell me what you’re looking for.",
        script: OnboardingFixtures.standard.transcript,
        onFinish: { _ in }
    )
}
