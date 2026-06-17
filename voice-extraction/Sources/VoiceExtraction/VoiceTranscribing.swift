import Foundation

/// The voice→text capability the app depends on.
///
/// Callers (and their previews/tests) should hold a `VoiceTranscribing` rather
/// than the concrete engine — the real ``SpeechTranscriptionService`` only runs
/// on a recent physical iPhone, so a ``StubTranscriber`` stands in everywhere
/// else (Simulator, unit tests, SwiftUI previews). Same composability seam as
/// `ComparisonCore`'s `HomeRanking`.
///
/// Lifecycle: ``prepare()`` (resolve locale + ensure model assets) →
/// ``startRecording()`` → observe ``transcript`` → ``stopRecording()``.
///
/// Permissions are a separate, app-level step (see ``SpeechPermissions``); call
/// them before `prepare()`.
@MainActor
public protocol VoiceTranscribing: AnyObject {
    /// Readiness of the transcription model. `startRecording()` no-ops until `.ready`.
    var modelState: ModelState { get }
    /// The live + finalized transcript, updated as audio streams in.
    var transcript: Transcript { get }
    /// Whether a recording is currently in progress.
    var isRecording: Bool { get }

    /// Resolve the locale and ensure model assets are present. Sets `modelState`.
    func prepare() async
    /// Begin capturing and transcribing. No-op unless `modelState == .ready`.
    func startRecording() async
    /// Stop capturing, finalize the transcript, and release audio resources.
    func stopRecording() async
}
