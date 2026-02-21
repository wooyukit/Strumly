import Foundation

// MARK: - ChordDataError

public enum ChordDataError: Error {
    case fileNotFound
}

// MARK: - ChordDataLoader

public enum ChordDataLoader {

    /// Loads chord data from the module's bundled JSON resource.
    /// - Returns: An array of `Chord` values decoded from the JSON file.
    /// - Throws: `ChordDataError.fileNotFound` if the resource cannot be located,
    ///           or a `DecodingError` if the JSON is malformed.
    public static func loadChords() throws -> [Chord] {
        try loadChords(from: .module)
    }

    /// Loads chord data from a specified bundle's JSON resource.
    /// - Parameter bundle: The bundle containing `chords.json`.
    /// - Returns: An array of `Chord` values decoded from the JSON file.
    /// - Throws: `ChordDataError.fileNotFound` if the resource cannot be located,
    ///           or a `DecodingError` if the JSON is malformed.
    public static func loadChords(from bundle: Bundle) throws -> [Chord] {
        guard let url = bundle.url(forResource: "chords", withExtension: "json") else {
            throw ChordDataError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Chord].self, from: data)
    }
}
