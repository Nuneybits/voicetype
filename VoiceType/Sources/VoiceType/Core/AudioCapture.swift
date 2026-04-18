import AVFoundation

final class AudioCapture {
    private let engine = AVAudioEngine()
    private var audioBuffer: [Float] = []
    private let bufferLock = NSLock()
    // One hour is a practical v0.1 ceiling without introducing chunked disk buffering.
    private let maxDuration: TimeInterval = 3600
    private let sampleRate: Double = 16000

    var isRecording: Bool { engine.isRunning }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws {
        bufferLock.lock()
        audioBuffer.removeAll()
        bufferLock.unlock()

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
                self.bufferLock.lock()
                if self.audioBuffer.count + samples.count <= maxSamples {
                    self.audioBuffer.append(contentsOf: samples)
                }
                self.bufferLock.unlock()
            }
        }

        // Skip engine.prepare() — it can create an aggregate audio device
        // that changes the output sample rate and disrupts music playback.
        // engine.start() prepares automatically.
        try engine.start()
    }

    func stopRecording() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        bufferLock.lock()
        let result = audioBuffer
        bufferLock.unlock()
        return result
    }

    /// Current audio level (0.0 to 1.0) for UI visualization.
    var currentLevel: Float {
        guard isRecording else { return 0 }
        bufferLock.lock()
        let recentSamples = Array(audioBuffer.suffix(1600))
        bufferLock.unlock()
        guard !recentSamples.isEmpty else { return 0 }
        let rms = sqrt(recentSamples.map { $0 * $0 }.reduce(0, +) / Float(recentSamples.count))
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
