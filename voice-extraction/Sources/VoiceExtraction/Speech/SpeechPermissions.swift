#if os(iOS)
import AVFoundation
import Speech

/// Requests the two authorizations a voice debrief needs: microphone and
/// speech recognition. Both Info.plist usage strings are still required on
/// iOS 26:
///   - `NSMicrophoneUsageDescription`
///   - `NSSpeechRecognitionUsageDescription`
public enum SpeechPermissions {

    /// Prompt for both permissions and report the result. Call before
    /// `SpeechTranscriptionService.prepare()`.
    public static func request() async -> PermissionStatus {
        let speech: Bool = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        return PermissionStatus(microphone: microphone, speechRecognition: speech)
    }
}
#endif
