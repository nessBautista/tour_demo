import Foundation
import Observation

/// A no-hardware ``VoiceTranscribing`` for the Simulator, SwiftUI previews, and
/// unit tests — everywhere the real ``SpeechTranscriptionService`` can't run.
///
/// It mimics the real lifecycle with a canned transcript: `prepare()` reports
/// `.ready`, `startRecording()` shows the text as volatile, `stopRecording()`
/// finalizes it. No audio, no permissions, no model assets.
@Observable
@MainActor
public final class StubTranscriber: VoiceTranscribing {
    public private(set) var modelState: ModelState = .unknown
    public private(set) var transcript = Transcript()
    public private(set) var isRecording = false

    @ObservationIgnored private let canned: String

    public init(
        canned: String = "The kitchen feels cramped, but the backyard is huge and it's really quiet."
    ) {
        self.canned = canned
    }

    public func prepare() async {
        modelState = .ready
    }

    public func startRecording() async {
        guard modelState == .ready, !isRecording else { return }
        transcript = Transcript(volatile: canned)
        isRecording = true
    }

    public func stopRecording() async {
        guard isRecording else { return }
        transcript = Transcript(finalized: canned)
        isRecording = false
    }
}
