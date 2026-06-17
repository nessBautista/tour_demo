import Foundation

/// Picks the best ``VoiceTranscribing`` the current environment can actually run.
///
/// This encodes *platform capability* — knowledge the package owns: the real
/// ``SpeechTranscriptionService`` only exists on iOS 26 and only does real work
/// on a physical device, so everywhere else (Simulator, macOS, older iOS) falls
/// back to ``StubTranscriber``.
///
/// It's a sensible **default**, not a mandate: the app keeps override authority
/// — force a stub for demos, UI tests, or SwiftUI previews by constructing one
/// directly. (Same division as `ComparisonCore` / the backend factory: the
/// package chooses from what it can see; the app overrides by policy.)
///
/// Note `#if targetEnvironment(simulator)` is doing real work here — `#if os(iOS)`
/// is also true on the Simulator, so an OS check alone can't exclude it; this
/// compile-time flag can. Anything only knowable at runtime (e.g. missing model
/// assets on older hardware) is still surfaced through `ModelState.unsupported`.
public enum VoiceTranscriberFactory {

    /// The best transcriber this build can run: the real engine on an iOS 26
    /// device, the stub everywhere else.
    @MainActor
    public static func makeDefault() -> any VoiceTranscribing {
        #if os(iOS) && !targetEnvironment(simulator)
        if #available(iOS 26, *) {
            return SpeechTranscriptionService()
        }
        #endif
        return StubTranscriber()
    }
}
