import SwiftUI
import StrumlyCore

// MARK: - LyricsChordView

/// Renders a single line of lyrics with chords positioned above at their correct offsets.
struct LyricsChordView: View {
    let line: SongLine
    let onChordTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            chordRow
            Text(line.lyrics)
                .font(.body)
        }
    }

    // MARK: - Chord Row

    /// Builds a row of chord names positioned at their character offsets using leading spaces.
    /// Chords are rendered in monospace, bold, blue, and are tappable.
    @ViewBuilder
    private var chordRow: some View {
        if line.chords.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 0) {
                let segments = chordSegments()
                ForEach(segments.indices, id: \.self) { index in
                    let segment = segments[index]

                    if segment.leadingSpaces > 0 {
                        Text(String(repeating: " ", count: segment.leadingSpaces))
                            .font(.system(.body, design: .monospaced))
                    }

                    Text(segment.chord)
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundStyle(.blue)
                        .onTapGesture {
                            onChordTap(segment.chord)
                        }
                }
            }
        }
    }

    // MARK: - Helpers

    /// A segment representing a chord and the number of leading spaces before it.
    private struct ChordSegment {
        let chord: String
        let leadingSpaces: Int
    }

    /// Converts chord positions into segments with computed leading spaces.
    /// Chords are sorted by offset. Each segment's leading spaces account for
    /// the width of previous chords and spaces.
    private func chordSegments() -> [ChordSegment] {
        let sorted = line.chords.sorted { $0.offset < $1.offset }
        var segments: [ChordSegment] = []
        var currentPosition = 0

        for chordPos in sorted {
            let spaces = max(0, chordPos.offset - currentPosition)
            segments.append(ChordSegment(chord: chordPos.chord, leadingSpaces: spaces))
            currentPosition = chordPos.offset + chordPos.chord.count
        }

        return segments
    }
}

// MARK: - Preview

#Preview {
    LyricsChordView(
        line: SongLine(
            lyrics: "Hello, is it me you're looking for?",
            chords: [
                ChordPosition(chord: "Am", offset: 0),
                ChordPosition(chord: "F", offset: 10),
                ChordPosition(chord: "C", offset: 20),
                ChordPosition(chord: "G", offset: 30)
            ]
        ),
        onChordTap: { chord in
            print("Tapped: \(chord)")
        }
    )
    .padding()
}
