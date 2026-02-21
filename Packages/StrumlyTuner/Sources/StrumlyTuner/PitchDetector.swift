import Foundation
import Accelerate

/// Autocorrelation-based pitch detector using the Accelerate framework.
///
/// Uses time-domain autocorrelation with `vDSP_dotpr` for efficient
/// computation, followed by parabolic interpolation for sub-sample accuracy.
/// The algorithm finds the first significant peak in the normalized
/// autocorrelation function, which corresponds to the fundamental frequency.
public final class PitchDetector: Sendable {
    private let sampleRate: Double
    private let minFrequency: Double
    private let maxFrequency: Double

    /// RMS threshold below which the signal is considered silence.
    private let silenceThreshold: Float = 0.01

    /// Fraction of the global autocorrelation peak that a local peak must
    /// exceed to be considered the fundamental. Using a threshold avoids
    /// octave errors by selecting the first significant peak (shortest lag).
    private let peakThreshold: Float = 0.9

    public init(sampleRate: Double = 44100, minFrequency: Double = 60, maxFrequency: Double = 1200) {
        self.sampleRate = sampleRate
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
    }

    /// Detect fundamental pitch from an audio buffer.
    ///
    /// - Parameter buffer: Array of audio samples (mono, floating point).
    /// - Returns: Detected frequency in Hz, or `nil` if the signal is too quiet
    ///   or no clear pitch is found.
    public func detectPitch(buffer: [Float]) -> Double? {
        guard !buffer.isEmpty else { return nil }

        // Step 1: Silence detection via RMS
        let rms = computeRMS(buffer)
        guard rms > silenceThreshold else { return nil }

        let count = buffer.count

        // Step 2: Calculate lag range from frequency bounds
        //   lag = sampleRate / frequency
        //   Higher frequency -> smaller lag, lower frequency -> larger lag
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = min(Int(sampleRate / minFrequency), count - 1)

        guard minLag < maxLag, maxLag < count else { return nil }

        // Step 3: Compute normalized autocorrelation for each lag using vDSP_dotpr
        let lagCount = maxLag - minLag + 1
        var autocorrelation = [Float](repeating: 0, count: lagCount)

        buffer.withUnsafeBufferPointer { bufferPtr in
            guard let base = bufferPtr.baseAddress else { return }
            for lag in minLag...maxLag {
                var result: Float = 0
                let overlapCount = count - lag
                vDSP_dotpr(base, 1, base.advanced(by: lag), 1, &result, vDSP_Length(overlapCount))
                // Normalize by overlap length so larger lags are not penalized
                autocorrelation[lag - minLag] = result / Float(overlapCount)
            }
        }

        // Step 4: Find the first significant peak in the autocorrelation.
        //
        // The autocorrelation of a periodic signal is itself periodic, so
        // there will be peaks at every multiple of the fundamental period.
        // The global maximum among these peaks might correspond to a larger
        // lag (lower frequency / sub-octave). To correctly identify the
        // fundamental, we:
        //   a) Find the global maximum value.
        //   b) Scan from the smallest lag and pick the first local peak
        //      whose value is at least `peakThreshold` of the global max.
        //
        // A local peak at index i satisfies:
        //   autocorrelation[i] > autocorrelation[i-1] &&
        //   autocorrelation[i] >= autocorrelation[i+1]

        // (a) Global maximum
        var globalMax: Float = -Float.infinity
        for value in autocorrelation {
            if value > globalMax { globalMax = value }
        }
        guard globalMax > 0 else { return nil }

        let threshold = peakThreshold * globalMax

        // (b) First significant local peak (scan from smallest lag)
        var peakIndex: Int? = nil
        for i in 1..<(autocorrelation.count - 1) {
            if autocorrelation[i] > autocorrelation[i - 1]
                && autocorrelation[i] >= autocorrelation[i + 1]
                && autocorrelation[i] >= threshold
            {
                peakIndex = i
                break
            }
        }

        guard let foundPeakIndex = peakIndex else { return nil }

        let bestLag = foundPeakIndex + minLag

        // Step 5: Parabolic interpolation for sub-sample accuracy
        //   Uses the three points around the peak to refine the lag estimate.
        let refinedLag: Double
        let alpha = autocorrelation[foundPeakIndex - 1]
        let beta = autocorrelation[foundPeakIndex]
        let gamma = autocorrelation[foundPeakIndex + 1]
        let denominator = alpha - 2.0 * beta + gamma
        if abs(denominator) > 1e-10 {
            let correction = 0.5 * Double(alpha - gamma) / Double(denominator)
            refinedLag = Double(bestLag) + correction
        } else {
            refinedLag = Double(bestLag)
        }

        // Step 6: Convert lag to frequency
        guard refinedLag > 0 else { return nil }
        let frequency = sampleRate / refinedLag

        // Sanity check: frequency should be within our detection range
        guard frequency >= minFrequency && frequency <= maxFrequency else { return nil }

        return frequency
    }

    // MARK: - Private Helpers

    /// Compute the root-mean-square of the buffer using Accelerate.
    private func computeRMS(_ buffer: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(buffer.count))
        return rms
    }
}
