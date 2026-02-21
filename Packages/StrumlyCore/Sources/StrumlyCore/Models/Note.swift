import Foundation

// MARK: - Note

public enum Note: String, CaseIterable, Codable, Sendable {
    case C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B

    // Lookup table for string -> Note, supporting sharps, flats, and enharmonics.
    private static let stringToNote: [String: Note] = [
        "C": .C,
        "C#": .CSharp,
        "Db": .CSharp,
        "D": .D,
        "D#": .DSharp,
        "Eb": .DSharp,
        "E": .E,
        "Fb": .E,      // enharmonic: Fb = E
        "E#": .F,      // enharmonic: E# = F
        "F": .F,
        "F#": .FSharp,
        "Gb": .FSharp,
        "G": .G,
        "G#": .GSharp,
        "Ab": .GSharp,
        "A": .A,
        "A#": .ASharp,
        "Bb": .ASharp,
        "B": .B,
        "Cb": .B,      // enharmonic: Cb = B
        "B#": .C,      // enharmonic: B# = C
    ]

    /// Custom initializer supporting sharp (#) and flat (b) notation.
    /// Examples: "C", "C#", "Db", "F#", "Gb", "Bb", "E#", "Cb", "B#", "Fb"
    public init?(rawValue: String) {
        guard let note = Self.stringToNote[rawValue] else {
            return nil
        }
        self = note
    }

    // Display names in sharp notation, indexed by case order.
    private static let displayNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Display name using sharp notation: "C", "C#", "D", etc.
    public var displayName: String {
        Self.displayNames[semitoneIndex]
    }

    /// Semitone index: C=0, C#=1, ..., B=11
    public var semitoneIndex: Int {
        guard let index = Self.allCases.firstIndex(of: self) else { return 0 }
        return Self.allCases.distance(from: Self.allCases.startIndex, to: index)
    }

    /// Transpose by N semitones (positive or negative), wrapping around the 12-tone scale.
    public func transposed(by semitones: Int) -> Note {
        // Use modulo with correction for negative values to always get 0..<12 range.
        let newIndex = ((semitoneIndex + semitones) % 12 + 12) % 12
        return Self.allCases[Self.allCases.index(Self.allCases.startIndex, offsetBy: newIndex)]
    }
}

// MARK: - GuitarString

public enum GuitarString: CaseIterable, Sendable, Equatable {
    case lowE, A, D, G, B, highE

    /// The note this string is tuned to in standard tuning.
    public var note: Note {
        switch self {
        case .lowE:  return .E
        case .A:     return .A
        case .D:     return .D
        case .G:     return .G
        case .B:     return .B
        case .highE: return .E
        }
    }

    /// The octave of this string in standard tuning.
    public var octave: Int {
        switch self {
        case .lowE:  return 2
        case .A:     return 2
        case .D:     return 3
        case .G:     return 3
        case .B:     return 3
        case .highE: return 4
        }
    }

    /// Standard tuning frequency in Hz, computed from the equal temperament formula.
    public var standardFrequency: Double {
        MusicTheory.frequency(note: note, octave: octave)
    }
}
