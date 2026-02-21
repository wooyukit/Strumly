import Foundation

// MARK: - DetectedNote

public struct DetectedNote: Equatable, Sendable {
    public let note: Note
    public let octave: Int
    public let centsOff: Double  // negative = flat, positive = sharp
    public let frequency: Double

    public init(note: Note, octave: Int, centsOff: Double, frequency: Double) {
        self.note = note
        self.octave = octave
        self.centsOff = centsOff
        self.frequency = frequency
    }
}

// MARK: - MusicTheory

public enum MusicTheory {

    /// A4 reference frequency in Hz.
    public static let a4Frequency: Double = 440.0

    // A4 is note A (semitone index 9) at octave 4.
    // The semitone distance from C0 to A4 is: (4 * 12) + 9 = 57
    private static let a4SemitoneFromC0: Int = 57

    /// Calculate the frequency (Hz) for a given note and octave using equal temperament.
    /// Formula: freq = 440 * 2^((semitonesFromA4) / 12)
    public static func frequency(note: Note, octave: Int) -> Double {
        let semitonesFromA4 = Double((octave * 12 + note.semitoneIndex) - a4SemitoneFromC0)
        return a4Frequency * pow(2.0, semitonesFromA4 / 12.0)
    }

    /// Detect the nearest note from a frequency.
    /// Returns the closest note, its octave, the cents offset, and the input frequency.
    public static func noteFromFrequency(_ freq: Double) -> DetectedNote {
        // Number of semitones from A4: n = 12 * log2(freq / 440)
        let semitonesFromA4 = 12.0 * log2(freq / a4Frequency)

        // Nearest semitone (rounded)
        let nearestSemitone = Int(round(semitonesFromA4))

        // Cents off from the nearest semitone
        let centsOff = (semitonesFromA4 - Double(nearestSemitone)) * 100.0

        // Convert semitone offset from A4 back to absolute semitone from C0
        let absoluteSemitone = nearestSemitone + a4SemitoneFromC0

        // Derive octave and note index
        let noteIndex = ((absoluteSemitone % 12) + 12) % 12
        let octave = (absoluteSemitone - noteIndex) / 12

        let note = Note.allCases[Note.allCases.index(Note.allCases.startIndex, offsetBy: noteIndex)]

        return DetectedNote(note: note, octave: octave, centsOff: centsOff, frequency: freq)
    }

    /// Transpose a chord string by a number of semitones.
    ///
    /// Parses the root note (with optional # or b) from the chord string,
    /// transposes it, and re-attaches the quality suffix.
    /// Examples: "Am" + 2 -> "Bm", "G7" + 1 -> "G#7", "F#m7" - 1 -> "Fm7"
    public static func transposeChord(_ chord: String, semitones: Int) -> String {
        guard !chord.isEmpty else { return chord }

        let (rootNote, suffix) = parseChordRoot(chord)
        guard let note = rootNote else { return chord }

        let transposed = note.transposed(by: semitones)
        return transposed.displayName + suffix
    }

    /// Find the closest guitar string (in standard tuning) to a given frequency.
    public static func closestGuitarString(to frequency: Double) -> GuitarString {
        // Compare using semitone distance (log scale) for musically correct "closest".
        var closest = GuitarString.allCases[0]
        var smallestDistance = Double.greatestFiniteMagnitude

        for string in GuitarString.allCases {
            let distance = abs(12.0 * log2(frequency / string.standardFrequency))
            if distance < smallestDistance {
                smallestDistance = distance
                closest = string
            }
        }

        return closest
    }

    // MARK: - Private Helpers

    /// Parse the root note from a chord string, returning the Note and the remaining suffix.
    /// Handles: "C", "C#", "Cb", "F#m7", "Bbmaj7", etc.
    private static func parseChordRoot(_ chord: String) -> (Note?, String) {
        guard !chord.isEmpty else { return (nil, chord) }

        let chars = Array(chord)

        // First character must be A-G
        let first = String(chars[0])
        guard first >= "A" && first <= "G" else { return (nil, chord) }

        // Check if second character is # or b
        if chars.count >= 2 {
            let second = chars[1]
            if second == "#" || second == "b" {
                let rootString = String(chars[0...1])
                let suffix = String(chord.dropFirst(2))
                return (Note(rawValue: rootString), suffix)
            }
        }

        // Single letter root
        let suffix = String(chord.dropFirst(1))
        return (Note(rawValue: first), suffix)
    }
}
