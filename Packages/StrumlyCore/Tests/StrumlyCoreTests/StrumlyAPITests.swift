import Testing
import Foundation
@testable import StrumlyCore

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Test Helpers

private func makeTestSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private let testBaseURL = URL(string: "https://api.strumly.test")!

private func makeSongJSON(id: String = "1", title: String = "Wonderwall", artist: String = "Oasis") -> String {
    """
    {
        "id": "\(id)",
        "title": "\(title)",
        "artist": "\(artist)",
        "key": "Em",
        "capoFret": 2,
        "coverImageURL": null,
        "playCount": 1500,
        "genre": "Rock",
        "sections": [
            {
                "type": "verse",
                "lines": [
                    {
                        "lyrics": "Today is gonna be the day",
                        "chords": [
                            {"chord": "Em7", "offset": 0}
                        ]
                    }
                ]
            }
        ]
    }
    """
}

private func makeArtistJSON(id: String = "1", name: String = "Oasis", songCount: Int = 25) -> String {
    """
    {
        "id": "\(id)",
        "name": "\(name)",
        "imageURL": null,
        "songCount": \(songCount)
    }
    """
}

// MARK: - StrumlyAPI Tests

@Suite("StrumlyAPI Networking", .serialized)
struct StrumlyAPITests {

    // MARK: - searchSongs

    @Test("searchSongs sends GET request with query parameter and decodes [Song]")
    func testSearchSongs() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let json = "[\(makeSongJSON())]"
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())
        let songs = try await api.searchSongs(query: "test")

        // Verify URL construction
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        #expect(urlString.contains("q=test"))
        #expect(capturedRequest?.httpMethod == "GET")

        // Verify decoding
        #expect(songs.count == 1)
        #expect(songs[0].title == "Wonderwall")
        #expect(songs[0].artist == "Oasis")
    }

    // MARK: - getPopularSongs

    @Test("getPopularSongs sends GET to /songs/popular and decodes [Song]")
    func testGetPopularSongs() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let json = "[\(makeSongJSON()), \(makeSongJSON(id: "2", title: "Let It Be", artist: "The Beatles"))]"
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())
        let songs = try await api.getPopularSongs(limit: 10)

        // Verify URL construction
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        #expect(urlString.contains("popular"))
        #expect(urlString.contains("limit=10"))
        #expect(capturedRequest?.httpMethod == "GET")

        // Verify decoding
        #expect(songs.count == 2)
        #expect(songs[0].title == "Wonderwall")
        #expect(songs[1].title == "Let It Be")
    }

    // MARK: - getSong

    @Test("getSong sends GET to /songs/{id} and decodes single Song")
    func testGetSongDetail() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let json = makeSongJSON(id: "1", title: "Wonderwall", artist: "Oasis")
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())
        let song = try await api.getSong(id: "1")

        // Verify URL construction
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        #expect(urlString.contains("songs/1"))
        #expect(capturedRequest?.httpMethod == "GET")

        // Verify decoding
        #expect(song.id == "1")
        #expect(song.title == "Wonderwall")
        #expect(song.artist == "Oasis")
    }

    // MARK: - Server Error

    @Test("API throws serverError when server returns 500")
    func testAPIErrorOnServerError() async throws {
        MockURLProtocol.requestHandler = { request in
            let data = Data()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())

        await #expect(throws: APIError.serverError(500)) {
            _ = try await api.searchSongs(query: "anything")
        }
    }

    // MARK: - getPopularArtists

    @Test("getPopularArtists sends GET to /artists/popular and decodes [Artist]")
    func testGetPopularArtists() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let json = "[\(makeArtistJSON()), \(makeArtistJSON(id: "2", name: "Coldplay", songCount: 30))]"
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())
        let artists = try await api.getPopularArtists(limit: 10)

        // Verify URL construction
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        #expect(urlString.contains("artists/popular"))
        #expect(urlString.contains("limit=10"))
        #expect(capturedRequest?.httpMethod == "GET")

        // Verify decoding
        #expect(artists.count == 2)
        #expect(artists[0].name == "Oasis")
        #expect(artists[1].name == "Coldplay")
    }

    // MARK: - getArtistSongs

    @Test("getArtistSongs sends GET to /artists/{id}/songs and decodes [Song]")
    func testGetArtistSongs() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let json = "[\(makeSongJSON())]"
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())
        let songs = try await api.getArtistSongs(artistId: "artist-1")

        // Verify URL construction
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        #expect(urlString.contains("artists/artist-1/songs"))
        #expect(capturedRequest?.httpMethod == "GET")

        // Verify decoding
        #expect(songs.count == 1)
        #expect(songs[0].title == "Wonderwall")
    }

    // MARK: - recordPlay

    @Test("recordPlay sends POST to /songs/{id}/play")
    func testRecordPlay() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let data = Data()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())
        try await api.recordPlay(songId: "song-1")

        // Verify URL construction
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        #expect(urlString.contains("songs/song-1/play"))
        #expect(capturedRequest?.httpMethod == "POST")
    }

    // MARK: - Decoding Error

    @Test("API throws decodingError when response JSON is malformed")
    func testDecodingError() async throws {
        MockURLProtocol.requestHandler = { request in
            let badJSON = "{ not valid json at all }".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, badJSON)
        }

        let api = StrumlyAPI(baseURL: testBaseURL, session: makeTestSession())

        await #expect(throws: APIError.decodingError) {
            _ = try await api.searchSongs(query: "anything")
        }
    }
}
