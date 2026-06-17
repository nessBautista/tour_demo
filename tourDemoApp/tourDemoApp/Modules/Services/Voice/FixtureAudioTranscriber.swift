//
//  FixtureAudioTranscriber.swift
//  tourDemoApp — Modules/Services/Voice
//
//  A fixture VoiceTranscribing for the Simulator and the demo video: it plays a
//  bundled audio clip and streams a matching transcript word-by-word, mimicking
//  the live on-device captions. Conforms to the voice-extraction package's
//  `VoiceTranscribing` seam, so the recording screen can't tell it apart from the
//  real engine.
//
//  On a real iOS 26 device the recording screen uses the package's
//  `SpeechTranscriptionService` instead (real mic) — see OnboardingVoiceFactory.
//
//  Drop the audio file in the app target as `<audioResource>.<audioExtension>`
//  (default `onboarding_preferences.m4a`). If it's absent, the transcript still
//  streams silently, so the flow always completes.
//

import Foundation
import Observation
import AVFoundation
import VoiceExtraction

@Observable
@MainActor
final class FixtureAudioTranscriber: VoiceTranscribing {
    private(set) var modelState: ModelState = .unknown
    private(set) var transcript = Transcript()
    private(set) var isRecording = false

    @ObservationIgnored private let script: String
    @ObservationIgnored private let audioResource: String?
    @ObservationIgnored private let audioExtension: String
    @ObservationIgnored private let wordInterval: Duration
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var revealTask: Task<Void, Never>?

    init(script: String,
         audioResource: String? = "onboarding_preferences",
         audioExtension: String = "m4a",
         wordInterval: Duration = .milliseconds(260)) {
        self.script = script
        self.audioResource = audioResource
        self.audioExtension = audioExtension
        self.wordInterval = wordInterval
    }

    func prepare() async {
        modelState = .ready
    }

    func startRecording() async {
        guard modelState == .ready, !isRecording else { return }
        transcript = Transcript()
        isRecording = true
        startAudio()
        revealTask = Task { [weak self] in await self?.streamScript() }
    }

    func stopRecording() async {
        guard isRecording else { return }
        revealTask?.cancel()
        revealTask = nil
        player?.stop()
        player = nil
        // Finalize the full script regardless of how far the reveal got, so the
        // extraction always sees the complete transcript.
        transcript = Transcript(finalized: script)
        isRecording = false
    }

    // MARK: Audio playback (the "fixture audio")

    private func startAudio() {
        guard let name = audioResource,
              let url = Bundle.main.url(forResource: name, withExtension: audioExtension) else {
            return  // no clip bundled yet — stream the captions silently
        }
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            // Non-fatal: the visual transcript still streams.
        }
    }

    // MARK: Caption streaming

    /// Reveal the script word-by-word into `volatile`, mimicking live dictation.
    private func streamScript() async {
        let words = script.split(separator: " ", omittingEmptySubsequences: false)
        var built = ""
        for (index, word) in words.enumerated() {
            if Task.isCancelled { return }
            built += (index == 0 ? "" : " ") + word
            transcript = Transcript(volatile: built)
            try? await Task.sleep(for: wordInterval)
        }
    }
}
