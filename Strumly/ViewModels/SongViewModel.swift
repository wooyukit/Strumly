import Combine
import Foundation
import StrumlyCore

@MainActor
final class SongViewModel: ObservableObject {
    @Published var popularSongs: [Song] = []
    @Published var popularArtists: [Artist] = []
    @Published var recentSongs: [Song] = []
    @Published var searchResults: [Song] = []
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    private let api: StrumlyAPI

    init(api: StrumlyAPI) { self.api = api }

    func loadHome() async {
        do {
            async let popular = api.getPopularSongs(limit: 20)
            async let artists = api.getPopularArtists(limit: 20)
            self.popularSongs = try await popular
            self.popularArtists = try await artists
        } catch {
            self.errorMessage = "Failed to load songs. Pull to retry."
        }
    }

    func search() async {
        guard !searchText.isEmpty else { searchResults = []; return }
        isSearching = true
        do { searchResults = try await api.searchSongs(query: searchText) }
        catch { errorMessage = "Search failed. Try again." }
        isSearching = false
    }

    func recordPlay(song: Song) {
        // Save to UserDefaults recent list
        var ids = UserDefaults.standard.stringArray(forKey: "recentSongIDs") ?? []
        ids.removeAll { $0 == song.id }
        ids.insert(song.id, at: 0)
        if ids.count > 20 { ids = Array(ids.prefix(20)) }
        UserDefaults.standard.set(ids, forKey: "recentSongIDs")
        Task { try? await api.recordPlay(songId: song.id) }
    }
}
