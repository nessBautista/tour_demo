#if os(iOS)
import AVFoundation

/// AVAudioEngine wrapper: session config, mic tap, interruption observation.
///
/// Interruptions (calls, Siri, alarms) must be surfaced and leave the recorder
/// in a clean state, never crash. Internal to the package — only
/// ``SpeechTranscriptionService`` drives it.
final class AudioCapture {
    private let engine = AVAudioEngine()
    private var interruptionObserver: NSObjectProtocol?

    /// Called on interruption begin/end with a human-readable description.
    var onInterruption: (@Sendable (String) -> Void)?

    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: nil
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue)
            else { return }
            self?.onInterruption?(type == .began ? "Audio session interrupted (began)" : "Interruption ended")
        }
    }

    /// Streams mic buffers in the input node's native format; the caller
    /// converts to the analyzer's preferred format.
    func start(onBuffer: @escaping @Sendable (AVAudioPCMBuffer) -> Void) throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            onBuffer(buffer)
        }
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }
}
#endif
