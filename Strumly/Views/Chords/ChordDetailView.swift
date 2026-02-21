import SwiftUI
import StrumlyCore
import StrumlyUI

struct ChordDetailView: View {
    let chord: Chord
    @State private var selectedVoicingIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chord name
                Text(chord.name)
                    .font(.largeTitle)
                    .bold()

                // Full name
                Text(chord.fullName)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Notes
                Text("Notes: \(chord.notes.joined(separator: " "))")
                    .font(.subheadline)

                // Voicing picker (only if multiple voicings)
                if chord.voicings.count > 1 {
                    Picker("Voicing", selection: $selectedVoicingIndex) {
                        ForEach(0..<chord.voicings.count, id: \.self) { index in
                            Text("Voicing \(index + 1)").tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // Chord diagram
                if !chord.voicings.isEmpty {
                    ChordDiagramView(
                        voicing: chord.voicings[selectedVoicingIndex],
                        chordName: chord.name
                    )
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle(chord.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: chord.id) {
            selectedVoicingIndex = 0
        }
    }
}

#Preview {
    NavigationStack {
        ChordDetailView(
            chord: Chord(
                id: "am",
                name: "Am",
                fullName: "A Minor",
                category: .minor,
                notes: ["A", "C", "E"],
                voicings: [
                    Voicing(
                        strings: [
                            StringFret(fret: -1),
                            StringFret(fret: 0),
                            StringFret(fret: 2, finger: 2),
                            StringFret(fret: 2, finger: 3),
                            StringFret(fret: 1, finger: 1),
                            StringFret(fret: 0)
                        ],
                        baseFret: 1
                    )
                ]
            )
        )
    }
}
