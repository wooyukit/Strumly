import SwiftUI
import StrumlyCore

// MARK: - SongCardView

struct SongCardView: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 140, height: 140)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }

            Text(song.title)
                .font(.subheadline)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            Text(song.artist)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
    }
}

// MARK: - ArtistCardView

struct ArtistCardView: View {
    let artist: Artist

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }

            Text(artist.name)
                .font(.subheadline)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}

#Preview("Song Card") {
    SongCardView(song: Song(
        id: "1",
        title: "Wonderwall",
        artist: "Oasis",
        key: "Em",
        playCount: 1000,
        sections: []
    ))
    .padding()
}

#Preview("Artist Card") {
    ArtistCardView(artist: Artist(
        id: "1",
        name: "Oasis",
        songCount: 12
    ))
    .padding()
}
