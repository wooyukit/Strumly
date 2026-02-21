import Foundation

// MARK: - Song

public struct Song: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let key: String              // e.g., "C", "Am", "G"
    public let capoFret: Int?
    public let coverImageURL: String?
    public let playCount: Int
    public let genre: String?
    public let sections: [SongSection]

    public init(
        id: String,
        title: String,
        artist: String,
        key: String,
        capoFret: Int? = nil,
        coverImageURL: String? = nil,
        playCount: Int,
        genre: String? = nil,
        sections: [SongSection]
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.key = key
        self.capoFret = capoFret
        self.coverImageURL = coverImageURL
        self.playCount = playCount
        self.genre = genre
        self.sections = sections
    }
}

// MARK: - SongSection

public struct SongSection: Codable, Sendable {
    public let type: String             // "verse", "chorus", "bridge", "intro", "outro"
    public let lines: [SongLine]

    public init(type: String, lines: [SongLine]) {
        self.type = type
        self.lines = lines
    }
}

// MARK: - SongLine

public struct SongLine: Codable, Sendable {
    public let lyrics: String
    public let chords: [ChordPosition]

    public init(lyrics: String, chords: [ChordPosition]) {
        self.lyrics = lyrics
        self.chords = chords
    }
}

// MARK: - ChordPosition

public struct ChordPosition: Codable, Sendable {
    public let chord: String            // e.g., "Am7"
    public let offset: Int              // character position

    public init(chord: String, offset: Int) {
        self.chord = chord
        self.offset = offset
    }
}

// MARK: - Artist

public struct Artist: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let imageURL: String?
    public let songCount: Int

    public init(id: String, name: String, imageURL: String? = nil, songCount: Int) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.songCount = songCount
    }
}
