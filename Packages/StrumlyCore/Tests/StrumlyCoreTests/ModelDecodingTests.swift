import Testing
import Foundation
@testable import StrumlyCore

// MARK: - Song Decoding Tests

@Suite("Song Decoding")
struct SongDecodingTests {

    @Test("Decode full Song JSON with sections, lines, and chords")
    func testDecodeSong() throws {
        let json = """
        {
            "id": "1",
            "title": "Wonderwall",
            "artist": "Oasis",
            "key": "Em",
            "capoFret": 2,
            "coverImageURL": null,
            "playCount": 1500,
            "genre": "Rock",
            "sections": [
                {
                    "type": "verse",
                    "lines": [
                        {
                            "lyrics": "Today is gonna be the day",
                            "chords": [
                                {"chord": "Em7", "offset": 0},
                                {"chord": "G", "offset": 15}
                            ]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let song = try JSONDecoder().decode(Song.self, from: json)

        #expect(song.id == "1")
        #expect(song.title == "Wonderwall")
        #expect(song.artist == "Oasis")
        #expect(song.key == "Em")
        #expect(song.capoFret == 2)
        #expect(song.coverImageURL == nil)
        #expect(song.playCount == 1500)
        #expect(song.genre == "Rock")

        // Sections
        #expect(song.sections.count == 1)
        let verse = song.sections[0]
        #expect(verse.type == "verse")
        #expect(verse.lines.count == 1)

        // Lines
        let line = verse.lines[0]
        #expect(line.lyrics == "Today is gonna be the day")
        #expect(line.chords.count == 2)

        // Chord positions
        #expect(line.chords[0].chord == "Em7")
        #expect(line.chords[0].offset == 0)
        #expect(line.chords[1].chord == "G")
        #expect(line.chords[1].offset == 15)
    }
}

// MARK: - Artist Decoding Tests

@Suite("Artist Decoding")
struct ArtistDecodingTests {

    @Test("Decode Artist JSON with name and songCount")
    func testDecodeArtist() throws {
        let json = """
        {
            "id": "1",
            "name": "Oasis",
            "imageURL": null,
            "songCount": 25
        }
        """.data(using: .utf8)!

        let artist = try JSONDecoder().decode(Artist.self, from: json)

        #expect(artist.id == "1")
        #expect(artist.name == "Oasis")
        #expect(artist.imageURL == nil)
        #expect(artist.songCount == 25)
    }
}

// MARK: - Chord Decoding Tests

@Suite("Chord Decoding")
struct ChordDecodingTests {

    @Test("Decode Chord JSON with voicing, strings, barres, and baseFret")
    func testDecodeChord() throws {
        let json = """
        {
            "id": "am",
            "name": "Am",
            "fullName": "A Minor",
            "category": "minor",
            "notes": ["A", "C", "E"],
            "voicings": [
                {
                    "strings": [
                        {"fret": -1, "finger": null},
                        {"fret": 0, "finger": null},
                        {"fret": 2, "finger": 2},
                        {"fret": 2, "finger": 3},
                        {"fret": 1, "finger": 1},
                        {"fret": 0, "finger": null}
                    ],
                    "barres": null,
                    "baseFret": 1
                }
            ]
        }
        """.data(using: .utf8)!

        let chord = try JSONDecoder().decode(Chord.self, from: json)

        #expect(chord.id == "am")
        #expect(chord.name == "Am")
        #expect(chord.fullName == "A Minor")
        #expect(chord.category == .minor)
        #expect(chord.notes == ["A", "C", "E"])

        // Voicings
        #expect(chord.voicings.count == 1)
        let voicing = chord.voicings[0]
        #expect(voicing.baseFret == 1)
        #expect(voicing.barres == nil)

        // Strings: 6 entries (low E to high E)
        #expect(voicing.strings.count == 6)

        // First string (low E) is muted: fret -1
        #expect(voicing.strings[0].fret == -1)
        #expect(voicing.strings[0].finger == nil)

        // Second string (A) is open: fret 0
        #expect(voicing.strings[1].fret == 0)

        // Third string (D) fret 2, finger 2
        #expect(voicing.strings[2].fret == 2)
        #expect(voicing.strings[2].finger == 2)

        // Fourth string (G) fret 2, finger 3
        #expect(voicing.strings[3].fret == 2)
        #expect(voicing.strings[3].finger == 3)

        // Fifth string (B) fret 1, finger 1
        #expect(voicing.strings[4].fret == 1)
        #expect(voicing.strings[4].finger == 1)

        // Sixth string (high E) is open: fret 0
        #expect(voicing.strings[5].fret == 0)
        #expect(voicing.strings[5].finger == nil)
    }
}
