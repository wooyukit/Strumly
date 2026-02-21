import Foundation
import Testing
@testable import StrumlyTuner

@Suite("PitchDetector Tests")
struct PitchDetectorTests {
    let sampleRate: Double = 44100
    let bufferSize: Int = 4096

    /// Helper: generate a pure sine wave at the given frequency.
    func sineWave(frequency: Double) -> [Float] {
        let sr = sampleRate
        let n = bufferSize
        return (0..<n).map { i in
            let phase: Double = 2.0 * Double.pi * frequency * Double(i) / sr
            return Float(sin(phase))
        }
    }

    @Test("Detects 440 Hz (A4) within ±2 Hz")
    func testDetect440Hz() {
        let detector = PitchDetector(sampleRate: sampleRate)
        let buffer = sineWave(frequency: 440.0)
        let pitch = detector.detectPitch(buffer: buffer)

        #expect(pitch != nil, "Expected a detected pitch for 440 Hz sine wave")
        if let pitch {
            #expect(abs(pitch - 440.0) < 2.0,
                    "Detected \(pitch) Hz, expected ~440 Hz (tolerance ±2)")
        }
    }

    @Test("Detects 329.63 Hz (E4) within ±2 Hz")
    func testDetect330Hz() {
        let detector = PitchDetector(sampleRate: sampleRate)
        let buffer = sineWave(frequency: 329.63)
        let pitch = detector.detectPitch(buffer: buffer)

        #expect(pitch != nil, "Expected a detected pitch for 329.63 Hz sine wave")
        if let pitch {
            #expect(abs(pitch - 329.63) < 2.0,
                    "Detected \(pitch) Hz, expected ~329.63 Hz (tolerance ±2)")
        }
    }

    @Test("Detects 82.41 Hz (low E2) within ±2 Hz")
    func testDetect82Hz() {
        let detector = PitchDetector(sampleRate: sampleRate)
        let buffer = sineWave(frequency: 82.41)
        let pitch = detector.detectPitch(buffer: buffer)

        #expect(pitch != nil, "Expected a detected pitch for 82.41 Hz sine wave")
        if let pitch {
            #expect(abs(pitch - 82.41) < 2.0,
                    "Detected \(pitch) Hz, expected ~82.41 Hz (tolerance ±2)")
        }
    }

    @Test("Silence (all zeros) returns nil")
    func testSilenceReturnsNil() {
        let detector = PitchDetector(sampleRate: sampleRate)
        let buffer = [Float](repeating: 0.0, count: bufferSize)
        let pitch = detector.detectPitch(buffer: buffer)

        #expect(pitch == nil, "Expected nil for silent buffer")
    }
}
