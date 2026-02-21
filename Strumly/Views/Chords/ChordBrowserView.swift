import SwiftUI
import StrumlyCore

struct ChordBrowserView: View {
    @StateObject private var viewModel = ChordViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.searchText.isEmpty {
                    Section("Categories") {
                        ForEach(viewModel.categories, id: \.self) { category in
                            NavigationLink(value: category) {
                                Label(
                                    category.rawValue.capitalized,
                                    systemImage: iconName(for: category)
                                )
                            }
                        }
                    }
                } else {
                    ForEach(viewModel.filteredChords) { chord in
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
                }
            }
            .navigationTitle("Chords")
            .searchable(text: $viewModel.searchText, prompt: "Search chords")
            .navigationDestination(for: ChordCategory.self) { category in
                ChordCategoryView(
                    category: category,
                    chords: viewModel.allChords.filter { $0.category == category }
                )
            }
            .navigationDestination(for: Chord.self) { chord in
                ChordDetailView(chord: chord)
            }
            .onAppear {
                viewModel.loadChords()
            }
        }
    }

    // MARK: - Helpers

    private func iconName(for category: ChordCategory) -> String {
        switch category {
        case .major:         return "hand.thumbsup"
        case .minor:         return "hand.thumbsdown"
        case .seventh:       return "7.circle"
        case .majorSeventh:  return "7.circle.fill"
        case .minorSeventh:  return "7.square"
        case .suspended:     return "pause.circle"
        case .diminished:    return "minus.circle"
        case .augmented:     return "plus.circle"
        }
    }
}

#Preview {
    ChordBrowserView()
}
