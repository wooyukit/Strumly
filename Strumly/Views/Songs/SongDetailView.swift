import SwiftUI
import StrumlyCore

// MARK: - SongDetailView

struct SongDetailView: View {
    let song: Song
    @State private var transposeSemitones: Int = 0
    @State private var showChordPopup: Bool = false
    @State private var selectedChordName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                transposeControls
                lyricsContent
            }
            .padding()
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChordPopup) {
            chordPopup
                .presentationDetents([.medium])
        }
    }

    // MARK: - Transposed Key

    /// The song key transposed by the current semitone offset.
    private var transposedKey: String {
        MusicTheory.transposeChord(song.key, semitones: transposeSemitones)
    }

    /// Creates a new SongLine with all chord names transposed.
    private func transposedLine(_ line: SongLine) -> SongLine {
        let transposedChords = line.chords.map { position in
            ChordPosition(
                chord: MusicTheory.transposeChord(position.chord, semitones: transposeSemitones),
                offset: position.offset
            )
        }
        return SongLine(lyrics: line.lyrics, chords: transposedChords)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(song.title)
                .font(.title.bold())

            Text(song.artist)
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("Key: \(transposedKey)", systemImage: "music.note")
                    .font(.subheadline)

                if let capo = song.capoFret, capo > 0 {
                    Label("Capo: Fret \(capo)", systemImage: "guitars")
                        .font(.subheadline)
                }
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Transpose Controls

    private var transposeControls: some View {
        HStack(spacing: 12) {
            Text("Transpose:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                transposeSemitones -= 1
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .accessibilityLabel("Transpose down")

            Text("\(transposeSemitones)")
                .font(.headline)
                .monospacedDigit()
                .frame(minWidth: 30)
                .multilineTextAlignment(.center)

            Button {
                transposeSemitones += 1
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .accessibilityLabel("Transpose up")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Lyrics Content

    private var lyricsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(song.sections.enumerated()), id: \.offset) { _, section in
                sectionView(section)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: SongSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.type.capitalized)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, 4)

            ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                LyricsChordView(
                    line: transposedLine(line),
                    onChordTap: { chordName in
                        selectedChordName = chordName
                        showChordPopup = true
                    }
                )
            }
        }
    }

    // MARK: - Chord Popup

    private var chordPopup: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text(selectedChordName)
                .font(.largeTitle)
                .bold()

            Text("Chord diagram coming soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SongDetailView(
            song: Song(
                id: "1",
                title: "Wonderwall",
                artist: "Oasis",
                key: "Em",
                capoFret: 2,
                playCount: 1000,
                genre: "Rock",
                sections: [
                    SongSection(type: "intro", lines: [
                        SongLine(lyrics: "", chords: [
                            ChordPosition(chord: "Em7", offset: 0),
                            ChordPosition(chord: "G", offset: 6),
                            ChordPosition(chord: "Dsus4", offset: 10),
                            ChordPosition(chord: "A7sus4", offset: 18)
                        ])
                    ]),
                    SongSection(type: "verse", lines: [
                        SongLine(
                            lyrics: "Today is gonna be the day that they're",
                            chords: [
                                ChordPosition(chord: "Em7", offset: 0),
                                ChordPosition(chord: "G", offset: 20)
                            ]
                        ),
                        SongLine(
                            lyrics: "gonna throw it back to you",
                            chords: [
                                ChordPosition(chord: "Dsus4", offset: 0),
                                ChordPosition(chord: "A7sus4", offset: 18)
                            ]
                        ),
                        SongLine(
                            lyrics: "By now you should've somehow",
                            chords: [
                                ChordPosition(chord: "Em7", offset: 0),
                                ChordPosition(chord: "G", offset: 18)
                            ]
                        ),
                        SongLine(
                            lyrics: "realized what you gotta do",
                            chords: [
                                ChordPosition(chord: "Dsus4", offset: 0),
                                ChordPosition(chord: "A7sus4", offset: 15)
                            ]
                        )
                    ]),
                    SongSection(type: "chorus", lines: [
                        SongLine(
                            lyrics: "And all the roads we have to walk are winding",
                            chords: [
                                ChordPosition(chord: "C", offset: 0),
                                ChordPosition(chord: "D", offset: 15),
                                ChordPosition(chord: "Em", offset: 30)
                            ]
                        ),
                        SongLine(
                            lyrics: "And all the lights that lead us there are blinding",
                            chords: [
                                ChordPosition(chord: "C", offset: 0),
                                ChordPosition(chord: "D", offset: 15),
                                ChordPosition(chord: "Em", offset: 30)
                            ]
                        )
                    ])
                ]
            )
        )
    }
}
