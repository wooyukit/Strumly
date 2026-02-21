#if canImport(AVFAudio)
import AVFAudio
import Foundation

/// Wrapper around `AVAudioEngine` that installs a tap on the microphone input
/// and feeds audio buffers to a ``PitchDetector``.
///
/// Usage:
/// ```swift
/// let engine = AudioEngine()
/// engine.onPitchDetected = { frequency in
///     // frequency is Double? — nil means silence
/// }
/// try engine.start()
/// // later...
/// engine.stop()
/// ```
///
/// The ``onPitchDetected`` callback is invoked on the audio render thread,
/// so callers must dispatch to the main actor before updating UI.
public final class AudioEngine {
    private let engine = AVAudioEngine()
    private let pitchDetector: PitchDetector
    private let bufferSize: AVAudioFrameCount = 4096

    /// Called each time a buffer is processed. The value is the detected
    /// fundamental frequency in Hz, or `nil` if the signal is silent.
    public var onPitchDetected: ((Double?) -> Void)?

    /// Create an audio engine with an injectable pitch detector.
    ///
    /// - Parameter pitchDetector: The pitch detection algorithm to use.
    ///   Defaults to a standard ``PitchDetector`` configured for guitar range.
    public init(pitchDetector: PitchDetector = PitchDetector()) {
        self.pitchDetector = pitchDetector
    }

    /// Start capturing audio from the device microphone and detecting pitch.
    ///
    /// - Throws: An error if the audio engine fails to start.
    public func start() throws {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.processBuffer(buffer)
        }

        engine.prepare()
        try engine.start()
    }

    /// Stop capturing audio and remove the input tap.
    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    // MARK: - Private

    /// Extract mono Float samples from the audio buffer, run pitch detection,
    /// and invoke the callback.
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = Int(buffer.frameLength)
        let channelPointer = channelData.pointee

        // Copy samples into a Swift array for PitchDetector
        let samples = Array(UnsafeBufferPointer(start: channelPointer, count: frameCount))

        let frequency = pitchDetector.detectPitch(buffer: samples)
        onPitchDetected?(frequency)
    }
}
#endif
