import Foundation

/// Async/await networking client for the Strumly REST API.
public final class StrumlyAPI: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    /// Creates a new API client.
    /// - Parameters:
    ///   - baseURL: The root URL for the Strumly API (e.g., `https://api.strumly.app`).
    ///   - session: The URLSession to use for requests. Defaults to `.shared`.
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Songs

    /// Search for songs matching a query string.
    /// - Parameter query: The search term.
    /// - Returns: An array of matching songs.
    public func searchSongs(query: String) async throws -> [Song] {
        var components = URLComponents(url: baseURL.appendingPathComponent("songs"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url)
    }

    /// Fetch popular songs.
    /// - Parameter limit: Maximum number of songs to return. Defaults to 20.
    /// - Returns: An array of popular songs.
    public func getPopularSongs(limit: Int = 20) async throws -> [Song] {
        var components = URLComponents(url: baseURL.appendingPathComponent("songs/popular"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url)
    }

    /// Fetch a single song by its ID.
    /// - Parameter id: The song identifier.
    /// - Returns: The requested song.
    public func getSong(id: String) async throws -> Song {
        let url = baseURL.appendingPathComponent("songs/\(id)")
        return try await fetch(url: url)
    }

    // MARK: - Artists

    /// Fetch popular artists.
    /// - Parameter limit: Maximum number of artists to return. Defaults to 20.
    /// - Returns: An array of popular artists.
    public func getPopularArtists(limit: Int = 20) async throws -> [Artist] {
        var components = URLComponents(url: baseURL.appendingPathComponent("artists/popular"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url)
    }

    /// Fetch all songs by a specific artist.
    /// - Parameter artistId: The artist identifier.
    /// - Returns: An array of the artist's songs.
    public func getArtistSongs(artistId: String) async throws -> [Song] {
        let url = baseURL.appendingPathComponent("artists/\(artistId)/songs")
        return try await fetch(url: url)
    }

    // MARK: - Play Tracking

    /// Record a play event for a song.
    /// - Parameter songId: The song identifier.
    public func recordPlay(songId: String) async throws {
        let url = baseURL.appendingPathComponent("songs/\(songId)/play")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (_, response) = try await perform(request: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        let statusCode = httpResponse.statusCode
        guard (200...299).contains(statusCode) else {
            throw APIError.serverError(statusCode)
        }
    }

    // MARK: - Private Helpers

    /// Generic fetch helper that performs a GET request and decodes the response.
    private func fetch<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await perform(request: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        let statusCode = httpResponse.statusCode
        guard (200...299).contains(statusCode) else {
            throw APIError.serverError(statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Perform a URL request, wrapping any URLSession errors into APIError.
    private func perform(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
}
