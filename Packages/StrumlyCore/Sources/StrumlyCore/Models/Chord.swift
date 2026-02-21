import Foundation

// MARK: - Chord

public struct Chord: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String             // "Am7"
    public let fullName: String         // "A Minor 7th"
    public let category: ChordCategory
    public let notes: [String]          // ["A", "C", "E", "G"]
    public let voicings: [Voicing]

    public init(
        id: String,
        name: String,
        fullName: String,
        category: ChordCategory,
        notes: [String],
        voicings: [Voicing]
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.category = category
        self.notes = notes
        self.voicings = voicings
    }
}

// MARK: - ChordCategory

public enum ChordCategory: String, Codable, CaseIterable, Sendable {
    case major
    case minor
    case seventh
    case majorSeventh
    case minorSeventh
    case suspended
    case diminished
    case augmented
}

// MARK: - Voicing

public struct Voicing: Codable, Hashable, Sendable {
    public let strings: [StringFret]    // 6 entries (low E to high E)
    public let barres: [Barre]?
    public let baseFret: Int

    public init(strings: [StringFret], barres: [Barre]? = nil, baseFret: Int) {
        self.strings = strings
        self.barres = barres
        self.baseFret = baseFret
    }
}

// MARK: - StringFret

public struct StringFret: Codable, Hashable, Sendable {
    public let fret: Int                // 0 = open, -1 = muted
    public let finger: Int?

    public init(fret: Int, finger: Int? = nil) {
        self.fret = fret
        self.finger = finger
    }
}

// MARK: - Barre

public struct Barre: Codable, Hashable, Sendable {
    public let fromString: Int
    public let toString: Int
    public let fret: Int

    public init(fromString: Int, toString: Int, fret: Int) {
        self.fromString = fromString
        self.toString = toString
        self.fret = fret
    }
}
