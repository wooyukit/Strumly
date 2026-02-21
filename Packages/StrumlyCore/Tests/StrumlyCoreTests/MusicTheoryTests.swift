import Testing
import Foundation
@testable import StrumlyCore

// MARK: - Note Enum Tests

@Suite("Note")
struct NoteTests {

    @Test("Init from string: natural notes")
    func noteFromStringNatural() {
        #expect(Note(rawValue: "C") == .C)
        #expect(Note(rawValue: "D") == .D)
        #expect(Note(rawValue: "E") == .E)
        #expect(Note(rawValue: "F") == .F)
        #expect(Note(rawValue: "G") == .G)
        #expect(Note(rawValue: "A") == .A)
        #expect(Note(rawValue: "B") == .B)
    }

    @Test("Init from string: sharp notes")
    func noteFromStringSharp() {
        #expect(Note(rawValue: "C#") == .CSharp)
        #expect(Note(rawValue: "D#") == .DSharp)
        #expect(Note(rawValue: "F#") == .FSharp)
        #expect(Note(rawValue: "G#") == .GSharp)
        #expect(Note(rawValue: "A#") == .ASharp)
    }

    @Test("Init from string: enharmonic flats")
    func noteFromStringFlat() {
        #expect(Note(rawValue: "Db") == .CSharp)
        #expect(Note(rawValue: "Eb") == .DSharp)
        #expect(Note(rawValue: "Gb") == .FSharp)
        #expect(Note(rawValue: "Ab") == .GSharp)
        #expect(Note(rawValue: "Bb") == .ASharp)
    }

    @Test("Init from invalid string returns nil")
    func noteFromStringInvalid() {
        #expect(Note(rawValue: "H") == nil)
        #expect(Note(rawValue: "") == nil)
        #expect(Note(rawValue: "Cb") == .B)
        #expect(Note(rawValue: "Fb") == .E)
        #expect(Note(rawValue: "E#") == .F)
        #expect(Note(rawValue: "B#") == .C)
    }

    @Test("Display name uses sharp notation")
    func displayName() {
        #expect(Note.C.displayName == "C")
        #expect(Note.CSharp.displayName == "C#")
        #expect(Note.D.displayName == "D")
        #expect(Note.DSharp.displayName == "D#")
        #expect(Note.E.displayName == "E")
        #expect(Note.F.displayName == "F")
        #expect(Note.FSharp.displayName == "F#")
        #expect(Note.G.displayName == "G")
        #expect(Note.GSharp.displayName == "G#")
        #expect(Note.A.displayName == "A")
        #expect(Note.ASharp.displayName == "A#")
        #expect(Note.B.displayName == "B")
    }

    @Test("Semitone index: C=0, B=11")
    func semitoneIndex() {
        #expect(Note.C.semitoneIndex == 0)
        #expect(Note.CSharp.semitoneIndex == 1)
        #expect(Note.D.semitoneIndex == 2)
        #expect(Note.DSharp.semitoneIndex == 3)
        #expect(Note.E.semitoneIndex == 4)
        #expect(Note.F.semitoneIndex == 5)
        #expect(Note.FSharp.semitoneIndex == 6)
        #expect(Note.G.semitoneIndex == 7)
        #expect(Note.GSharp.semitoneIndex == 8)
        #expect(Note.A.semitoneIndex == 9)
        #expect(Note.ASharp.semitoneIndex == 10)
        #expect(Note.B.semitoneIndex == 11)
    }

    @Test("Transpose up: basic cases")
    func transposeUp() {
        #expect(Note.C.transposed(by: 2) == .D)
        #expect(Note.B.transposed(by: 1) == .C)
        #expect(Note.G.transposed(by: 5) == .C)
        #expect(Note.A.transposed(by: 3) == .C)
        #expect(Note.C.transposed(by: 12) == .C)
        #expect(Note.E.transposed(by: 0) == .E)
    }

    @Test("Transpose down: basic cases")
    func transposeDown() {
        #expect(Note.D.transposed(by: -2) == .C)
        #expect(Note.C.transposed(by: -1) == .B)
        #expect(Note.C.transposed(by: -12) == .C)
        #expect(Note.E.transposed(by: -5) == .B)
    }

    @Test("All 12 notes are in CaseIterable")
    func caseIterable() {
        #expect(Note.allCases.count == 12)
    }
}

// MARK: - GuitarString Tests

@Suite("GuitarString")
struct GuitarStringTests {

    @Test("Guitar strings have correct notes")
    func guitarStringNotes() {
        #expect(GuitarString.lowE.note == .E)
        #expect(GuitarString.A.note == .A)
        #expect(GuitarString.D.note == .D)
        #expect(GuitarString.G.note == .G)
        #expect(GuitarString.B.note == .B)
        #expect(GuitarString.highE.note == .E)
    }

    @Test("Guitar strings have correct octaves")
    func guitarStringOctaves() {
        #expect(GuitarString.lowE.octave == 2)
        #expect(GuitarString.A.octave == 2)
        #expect(GuitarString.D.octave == 3)
        #expect(GuitarString.G.octave == 3)
        #expect(GuitarString.B.octave == 3)
        #expect(GuitarString.highE.octave == 4)
    }

    @Test("Guitar string standard frequencies are correct")
    func guitarStringFrequencies() {
        // Standard tuning frequencies (Hz):
        // E2 = 82.41, A2 = 110.0, D3 = 146.83, G3 = 196.0, B3 = 246.94, E4 = 329.63
        #expect(abs(GuitarString.lowE.standardFrequency - 82.41) < 0.5)
        #expect(abs(GuitarString.A.standardFrequency - 110.0) < 0.5)
        #expect(abs(GuitarString.D.standardFrequency - 146.83) < 0.5)
        #expect(abs(GuitarString.G.standardFrequency - 196.0) < 0.5)
        #expect(abs(GuitarString.B.standardFrequency - 246.94) < 0.5)
        #expect(abs(GuitarString.highE.standardFrequency - 329.63) < 0.5)
    }

    @Test("All 6 guitar strings in CaseIterable")
    func caseIterable() {
        #expect(GuitarString.allCases.count == 6)
    }
}

// MARK: - MusicTheory Tests

@Suite("MusicTheory")
struct MusicTheoryTests {

    @Test("Frequency for A4 = 440 Hz")
    func frequencyA4() {
        let freq = MusicTheory.frequency(note: .A, octave: 4)
        #expect(abs(freq - 440.0) < 0.01)
    }

    @Test("Frequency for A3 = 220 Hz (one octave down)")
    func frequencyA3() {
        let freq = MusicTheory.frequency(note: .A, octave: 3)
        #expect(abs(freq - 220.0) < 0.01)
    }

    @Test("Frequency for C4 ~ 261.63 Hz")
    func frequencyC4() {
        let freq = MusicTheory.frequency(note: .C, octave: 4)
        #expect(abs(freq - 261.63) < 0.1)
    }

    @Test("Frequency for A5 = 880 Hz (one octave up)")
    func frequencyA5() {
        let freq = MusicTheory.frequency(note: .A, octave: 5)
        #expect(abs(freq - 880.0) < 0.01)
    }

    @Test("Note from frequency: 440 Hz = A4, 0 cents")
    func noteFromFrequency440() {
        let detected = MusicTheory.noteFromFrequency(440.0)
        #expect(detected.note == .A)
        #expect(detected.octave == 4)
        #expect(abs(detected.centsOff) < 0.5)
        #expect(abs(detected.frequency - 440.0) < 0.01)
    }

    @Test("Note from frequency: 445 Hz = A4, sharp (positive cents)")
    func noteFromFrequency445() {
        let detected = MusicTheory.noteFromFrequency(445.0)
        #expect(detected.note == .A)
        #expect(detected.octave == 4)
        #expect(detected.centsOff > 0)
        // 445 Hz is about 19.6 cents sharp of A4
        #expect(abs(detected.centsOff - 19.6) < 1.0)
    }

    @Test("Note from frequency: 435 Hz = A4, flat (negative cents)")
    func noteFromFrequency435() {
        let detected = MusicTheory.noteFromFrequency(435.0)
        #expect(detected.note == .A)
        #expect(detected.octave == 4)
        #expect(detected.centsOff < 0)
    }

    @Test("Note from frequency: 261.63 Hz = C4")
    func noteFromFrequencyC4() {
        let detected = MusicTheory.noteFromFrequency(261.63)
        #expect(detected.note == .C)
        #expect(detected.octave == 4)
        #expect(abs(detected.centsOff) < 1.0)
    }

    @Test("Note from frequency: 82.41 Hz = E2 (low E guitar string)")
    func noteFromFrequencyE2() {
        let detected = MusicTheory.noteFromFrequency(82.41)
        #expect(detected.note == .E)
        #expect(detected.octave == 2)
        #expect(abs(detected.centsOff) < 1.0)
    }

    @Test("Transpose chord string: simple cases")
    func transposeChordSimple() {
        #expect(MusicTheory.transposeChord("C", semitones: 5) == "F")
        #expect(MusicTheory.transposeChord("G", semitones: 2) == "A")
        #expect(MusicTheory.transposeChord("D", semitones: -2) == "C")
    }

    @Test("Transpose chord string: minor chords")
    func transposeChordMinor() {
        #expect(MusicTheory.transposeChord("Am", semitones: 2) == "Bm")
        #expect(MusicTheory.transposeChord("Em", semitones: 3) == "Gm")
    }

    @Test("Transpose chord string: seventh chords")
    func transposeChordSeventh() {
        #expect(MusicTheory.transposeChord("G7", semitones: 1) == "G#7")
        #expect(MusicTheory.transposeChord("Cmaj7", semitones: 2) == "Dmaj7")
    }

    @Test("Transpose chord string: sharp root note")
    func transposeChordSharpRoot() {
        #expect(MusicTheory.transposeChord("F#m7", semitones: -1) == "Fm7")
        #expect(MusicTheory.transposeChord("C#", semitones: 1) == "D")
    }

    @Test("Transpose chord string: flat root note")
    func transposeChordFlatRoot() {
        #expect(MusicTheory.transposeChord("Bb", semitones: 1) == "B")
        #expect(MusicTheory.transposeChord("Ebm", semitones: 2) == "Fm")
    }

    @Test("Transpose chord string: wrap around")
    func transposeChordWrapAround() {
        #expect(MusicTheory.transposeChord("B", semitones: 1) == "C")
        #expect(MusicTheory.transposeChord("C", semitones: -1) == "B")
    }

    @Test("Closest guitar string to frequency")
    func closestGuitarString() {
        // Near E2 (82.41 Hz)
        #expect(MusicTheory.closestGuitarString(to: 80.0) == .lowE)
        // Near A2 (110 Hz)
        #expect(MusicTheory.closestGuitarString(to: 112.0) == .A)
        // Near D3 (146.83 Hz)
        #expect(MusicTheory.closestGuitarString(to: 145.0) == .D)
        // Near G3 (196 Hz)
        #expect(MusicTheory.closestGuitarString(to: 200.0) == .G)
        // Near B3 (246.94 Hz)
        #expect(MusicTheory.closestGuitarString(to: 250.0) == .B)
        // Near E4 (329.63 Hz)
        #expect(MusicTheory.closestGuitarString(to: 330.0) == .highE)
    }

    @Test("DetectedNote is Equatable")
    func detectedNoteEquatable() {
        let a = DetectedNote(note: .A, octave: 4, centsOff: 0, frequency: 440.0)
        let b = DetectedNote(note: .A, octave: 4, centsOff: 0, frequency: 440.0)
        #expect(a == b)
    }
}
