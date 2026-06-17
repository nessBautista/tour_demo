#if os(iOS)
import AVFoundation
import Foundation
import Observation
import Speech

/// The real on-device transcription engine: `SpeechAnalyzer` + `SpeechTranscriber`
/// (iOS 26+, on-device only — audio never leaves the device).
///
/// Shape per WWDC25 session 277: a transcriber module attaches to an analyzer;
/// mic buffers are converted and fed in via an `AsyncStream`; volatile and final
/// results are read back off `transcriber.results`.
///
/// Runs only on a recent physical iPhone — the Simulator ships no model assets
/// (`supportedLocales` is empty there). Use ``StubTranscriber`` elsewhere.
@available(iOS 26, *)
@Observable
@MainActor
public final class SpeechTranscriptionService: VoiceTranscribing {
    public private(set) var modelState: ModelState = .unknown
    public private(set) var transcript = Transcript()
    public private(set) var isRecording = false
    /// Human-readable event trail — handy for a developer view; not part of the protocol.
    public private(set) var sessionLog: [String] = []

    @ObservationIgnored private var locale = Locale.current
    @ObservationIgnored private let audio = AudioCapture()
    @ObservationIgnored private let converter = BufferConverter()

    @ObservationIgnored private var transcriber: SpeechTranscriber?
    @ObservationIgnored private var analyzer: SpeechAnalyzer?
    @ObservationIgnored private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    @ObservationIgnored private var resultsTask: Task<Void, Never>?

    public init() {}

    // MARK: - Model assets

    public func prepare() async {
        modelState = .checking
        log("Locale: \(locale.identifier)")

        let supported = await SpeechTranscriber.supportedLocales
        log("Supported locales: \(supported.count)")

        // Empty list = SpeechTranscriber unavailable on this hardware (Simulator
        // / older iPhones). Not a locale problem.
        guard !supported.isEmpty else {
            modelState = .unsupported(
                "SpeechTranscriber unavailable here (Simulator / older hardware) — run on a recent physical iPhone with iOS 26"
            )
            return
        }
        guard let resolved = LocaleResolver.resolve(Locale.current, against: supported) else {
            let language = Locale.current.language.languageCode?.identifier ?? "?"
            modelState = .unsupported("No supported locale for language '\(language)' (device: \(Locale.current.identifier))")
            return
        }
        if resolved.identifier(.bcp47) != Locale.current.identifier(.bcp47) {
            log("Device locale \(Locale.current.identifier) unsupported — falling back to \(resolved.identifier)")
        }
        locale = resolved

        let transcriber = makeTranscriber()
        let installed = await Set(SpeechTranscriber.installedLocales)
        if installed.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
            log("Model assets already installed")
            modelState = .ready
            return
        }

        do {
            log("Model assets missing — requesting download…")
            modelState = .downloading
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }
            log("Model assets installed")
            modelState = .ready
        } catch {
            modelState = .failed("Asset download failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Recording lifecycle

    public func startRecording() async {
        guard modelState == .ready, !isRecording else { return }
        transcript = Transcript()

        let transcriber = makeTranscriber()
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.transcriber = transcriber
        self.analyzer = analyzer

        do {
            guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                log("ERROR: no compatible audio format")
                return
            }

            let (inputSequence, continuation) = AsyncStream<AnalyzerInput>.makeStream()
            inputContinuation = continuation

            // Volatile results overwrite each other; a final result is appended
            // and the volatile slate cleared (avoids the duplicate-text bug).
            resultsTask = Task { [weak self] in
                do {
                    for try await result in transcriber.results {
                        let text = String(result.text.characters)
                        await MainActor.run {
                            guard let self else { return }
                            if result.isFinal {
                                self.transcript.finalized += text
                                self.transcript.volatile = ""
                            } else {
                                self.transcript.volatile = text
                            }
                        }
                    }
                } catch {
                    await MainActor.run { self?.log("Results stream error: \(error.localizedDescription)") }
                }
            }

            try await analyzer.start(inputSequence: inputSequence)

            audio.onInterruption = { [weak self] description in
                Task { @MainActor in
                    self?.log("INTERRUPTION: \(description)")
                    await self?.stopRecording()
                }
            }
            try audio.configureSession()

            let converter = self.converter
            try audio.start { buffer in
                guard let converted = try? converter.convert(buffer, to: analyzerFormat) else { return }
                continuation.yield(AnalyzerInput(buffer: converted))
            }

            isRecording = true
            log("Recording started")
        } catch {
            log("ERROR starting: \(error.localizedDescription)")
            await stopRecording()
        }
    }

    public func stopRecording() async {
        guard isRecording || inputContinuation != nil else { return }
        audio.stop()
        inputContinuation?.finish()
        inputContinuation = nil
        do {
            try await analyzer?.finalizeAndFinishThroughEndOfInput()
        } catch {
            log("Finalize error: \(error.localizedDescription)")
        }
        resultsTask?.cancel()
        resultsTask = nil
        analyzer = nil
        transcriber = nil
        isRecording = false
        log("Recording stopped — \(transcript.finalized.count) chars finalized")
    }

    // MARK: - Helpers

    private func makeTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
    }

    private func log(_ message: String) {
        sessionLog.append("[\(Date().formatted(date: .omitted, time: .standard))] \(message)")
    }
}
#endif
