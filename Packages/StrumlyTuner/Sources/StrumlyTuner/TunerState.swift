import Foundation

/// Observable state model for the guitar tuner, designed for SwiftUI binding.
///
/// All properties are published on the main actor so SwiftUI views can
/// subscribe safely. The ``update(frequency:note:octave:cents:stringName:)``
/// method is the single entry point for the tuner pipeline to push new
/// readings, and ``reset()`` clears everything back to the idle state.
@MainActor
public final class TunerState: ObservableObject {
    /// Whether the tuner is currently listening for audio input.
    @Published public var isActive: Bool = false

    /// The most recently detected fundamental frequency in Hz, or `nil` if silent.
    @Published public var detectedFrequency: Double?

    /// The note name closest to the detected frequency (e.g. "A", "E").
    @Published public var detectedNote: String = "\u{2014}"

    /// The octave of the detected note (e.g. 4 for A4).
    @Published public var detectedOctave: Int = 0

    /// How many cents the detected pitch is away from the nearest note.
    /// Negative means flat, positive means sharp.
    @Published public var centsOff: Double = 0.0

    /// The name of the closest guitar string (e.g. "1st (E4)").
    @Published public var closestStringName: String = ""

    public init() {}

    /// Update all tuner readings at once from a single pitch detection cycle.
    ///
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz, or `nil` for silence.
    ///   - note: Nearest note name (e.g. "A").
    ///   - octave: Octave number for the detected note.
    ///   - cents: Cent deviation from the nearest note.
    ///   - stringName: Display name of the closest guitar string.
    public func update(frequency: Double?, note: String, octave: Int, cents: Double, stringName: String) {
        self.detectedFrequency = frequency
        self.detectedNote = note
        self.detectedOctave = octave
        self.centsOff = cents
        self.closestStringName = stringName
    }

    /// Reset all readings to their idle defaults.
    public func reset() {
        detectedFrequency = nil
        detectedNote = "\u{2014}"
        detectedOctave = 0
        centsOff = 0.0
        closestStringName = ""
    }
}
