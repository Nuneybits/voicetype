import AVFoundation

final class AudioCapture {
    private let engine = AVAudioEngine()
    private var audioBuffer: [Float] = []
    private let maxDuration: TimeInterval = 30
    private let sampleRate: Double = 16000

    var isRecording: Bool { engine.isRunning }

    /// Request microphone permission. Returns true if granted.
    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Start recording from the microphone.
    func startRecording() throws {
        audioBuffer.removeAll()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioCaptureError.formatCreationFailed
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioCaptureError.converterCreationFailed
        }

        let maxSamples = Int(sampleRate * maxDuration)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * self.sampleRate / inputFormat.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if let channelData = convertedBuffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(
                    start: channelData,
                    count: Int(convertedBuffer.frameLength)
                ))
                if self.audioBuffer.count + samples.count <= maxSamples {
                    self.audioBuffer.append(contentsOf: samples)
                }
            }
        }

        engine.prepare()
        try engine.start()
    }

    /// Stop recording and return the captured audio samples.
    func stopRecording() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        return audioBuffer
    }

    /// Current audio level (0.0 to 1.0) for UI visualization.
    var currentLevel: Float {
        guard isRecording else { return 0 }
        let recentSamples = audioBuffer.suffix(1600) // last 100ms at 16kHz
        let rms = sqrt(recentSamples.map { $0 * $0 }.reduce(0, +) / Float(max(recentSamples.count, 1)))
        return min(rms * 5, 1.0)
    }
}

enum AudioCaptureError: Error, LocalizedError {
    case formatCreationFailed
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed: "Failed to create audio format"
        case .converterCreationFailed: "Failed to create audio converter"
        }
    }
}
