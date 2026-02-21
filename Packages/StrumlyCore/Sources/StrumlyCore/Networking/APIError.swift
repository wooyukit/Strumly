import Foundation

/// Errors that can occur when communicating with the Strumly API.
public enum APIError: Error, Equatable {
    /// The constructed URL was invalid.
    case invalidURL
    /// The server returned a non-success HTTP status code.
    case serverError(Int)
    /// The response body could not be decoded into the expected type.
    case decodingError
    /// A network-level error occurred (e.g., no connectivity).
    case networkError(String)
}
