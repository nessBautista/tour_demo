#if os(iOS)
import AVFoundation

/// Converts mic buffers (the input node's native format) to the analyzer's
/// format (usually 16 kHz mono). One reusable converter, per the WWDC25 pattern.
final class BufferConverter: @unchecked Sendable {
    private var converter: AVAudioConverter?

    func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard buffer.format != format else { return buffer }

        if converter == nil || converter?.outputFormat != format {
            converter = AVAudioConverter(from: buffer.format, to: format)
        }
        guard let converter else {
            throw NSError(domain: "BufferConverter", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot create AVAudioConverter"])
        }

        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up) + 1024)
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw NSError(domain: "BufferConverter", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot allocate output buffer"])
        }

        var conversionError: NSError?
        var bufferConsumed = false
        converter.convert(to: output, error: &conversionError) { _, statusPointer in
            if bufferConsumed {
                statusPointer.pointee = .noDataNow
                return nil
            }
            bufferConsumed = true
            statusPointer.pointee = .haveData
            return buffer
        }
        if let conversionError { throw conversionError }
        return output
    }
}
#endif
