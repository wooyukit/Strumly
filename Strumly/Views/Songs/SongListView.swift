import SwiftUI
import StrumlyCore

struct SongListView: View {
    @StateObject private var viewModel: SongViewModel

    init(api: StrumlyAPI) {
        _viewModel = StateObject(wrappedValue: SongViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.searchText.isEmpty {
                    homeContent
                } else {
                    searchContent
                }
            }
            .navigationTitle("Songs")
            .searchable(text: $viewModel.searchText, prompt: "Search songs")
            .onChange(of: viewModel.searchText) {
                Task { await viewModel.search() }
            }
            .task {
                await viewModel.loadHome()
            }
        }
    }

    // MARK: - Home Content

    @ViewBuilder
    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !viewModel.recentSongs.isEmpty {
                    sectionHeader("Recently Played")
                    horizontalSongScroll(songs: viewModel.recentSongs)
                }

                if !viewModel.popularSongs.isEmpty {
                    sectionHeader("Most Popular")
                    horizontalSongScroll(songs: viewModel.popularSongs)
                }

                if !viewModel.popularArtists.isEmpty {
                    sectionHeader("Popular Artists")
                    horizontalArtistScroll(artists: viewModel.popularArtists)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Search Content

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.searchResults.isEmpty {
            ContentUnavailableView.search
        } else {
            List(viewModel.searchResults) { song in
                NavigationLink {
                    // Placeholder until SongDetailView is implemented (Task 11)
                    Text("Song Detail: \(song.title)")
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.headline)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .padding(.horizontal)
    }

    private func horizontalSongScroll(songs: [Song]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(songs) { song in
                    NavigationLink {
                        // Placeholder until SongDetailView is implemented (Task 11)
                        Text("Song Detail: \(song.title)")
                    } label: {
                        SongCardView(song: song)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func horizontalArtistScroll(artists: [Artist]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(artists) { artist in
                    ArtistCardView(artist: artist)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    SongListView(api: StrumlyAPI(baseURL: URL(string: "https://strumly-api.web.app/api")!))
}
