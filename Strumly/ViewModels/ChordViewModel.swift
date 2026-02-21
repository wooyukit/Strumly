import Combine
import Foundation
import StrumlyCore

@MainActor
final class ChordViewModel: ObservableObject {
    @Published var allChords: [Chord] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ChordCategory?

    var filteredChords: [Chord] {
        var result = allChords
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var categories: [ChordCategory] { ChordCategory.allCases }

    func loadChords() {
        do { allChords = try ChordDataLoader.loadChords() }
        catch { allChords = [] }
    }
}
