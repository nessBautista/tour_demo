import Foundation

/// Whether the two authorizations a voice debrief needs have been granted.
/// Both Info.plist usage strings are still required on iOS 26.
public struct PermissionStatus: Equatable, Sendable {
    public var microphone: Bool
    public var speechRecognition: Bool

    public init(microphone: Bool, speechRecognition: Bool) {
        self.microphone = microphone
        self.speechRecognition = speechRecognition
    }

    public var allGranted: Bool { microphone && speechRecognition }
}
