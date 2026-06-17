import Foundation

/// Readiness of the on-device transcription model for the resolved locale.
///
/// `unsupported` carries a human-readable reason — most often the Simulator or
/// older hardware, where `SpeechTranscriber` ships no assets at all (not a
/// locale problem, a platform one).
public enum ModelState: Equatable, Sendable {
    case unknown
    case checking
    case downloading
    case ready
    case unsupported(String)
    case failed(String)
}
