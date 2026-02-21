import Testing
import Foundation
@testable import StrumlyCore

@Suite("ChordDataLoader Tests")
struct ChordDataLoaderTests {

    @Test func testLoadChordsFromBundle() throws {
        let chords = try ChordDataLoader.loadChords()
        #expect(!chords.isEmpty)
        #expect(chords.count >= 12)
    }

    @Test func testFindChordByName() throws {
        let chords = try ChordDataLoader.loadChords()
        let am = chords.first { $0.name == "Am" }
        #expect(am != nil)
        #expect(am?.category == .minor)
        #expect(am?.fullName == "A Minor")
    }

    @Test func testFilterChordsByCategory() throws {
        let chords = try ChordDataLoader.loadChords()
        let majorChords = chords.filter { $0.category == .major }
        #expect(!majorChords.isEmpty)
        #expect(majorChords.count >= 6)

        let minorChords = chords.filter { $0.category == .minor }
        #expect(!minorChords.isEmpty)
        #expect(minorChords.count >= 3)

        let seventhChords = chords.filter { $0.category == .seventh }
        #expect(!seventhChords.isEmpty)
        #expect(seventhChords.count >= 3)
    }

    @Test func testEachChordHasVoicings() throws {
        let chords = try ChordDataLoader.loadChords()
        for chord in chords {
            #expect(!chord.voicings.isEmpty)
            for voicing in chord.voicings {
                #expect(voicing.strings.count == 6)
            }
        }
    }

    @Test func testEachChordHasNotes() throws {
        let chords = try ChordDataLoader.loadChords()
        for chord in chords {
            #expect(!chord.notes.isEmpty)
        }
    }

    @Test func testFileNotFoundError() {
        let emptyBundle = Bundle(path: "/nonexistent") ?? Bundle.main
        #expect(throws: ChordDataError.self) {
            _ = try ChordDataLoader.loadChords(from: emptyBundle)
        }
    }
}
