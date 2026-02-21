import SwiftUI
import StrumlyCore

struct ChordCategoryView: View {
    let category: ChordCategory
    let chords: [Chord]

    var body: some View {
        List(chords) { chord in
            NavigationLink(value: chord) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chord.name)
                        .font(.headline)
                    Text(chord.fullName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(category.rawValue.capitalized)
        .navigationDestination(for: Chord.self) { chord in
            ChordDetailView(chord: chord)
        }
    }
}

#Preview {
    NavigationStack {
        ChordCategoryView(
            category: .major,
            chords: []
        )
    }
}
