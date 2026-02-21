# Strumly Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build Strumly, a SwiftUI guitar companion app (iPhone, iPad, Apple Watch) with songbook, chord library, and tuner.

**Architecture:** SwiftUI multiplatform app with modular Swift packages (StrumlyCore, StrumlyUI, StrumlyTuner). Firebase backend (Cloud Functions + Firestore) for song data API. Local JSON bundle for chord data. Autocorrelation-based pitch detection for tuner.

**Tech Stack:** Swift, SwiftUI, Swift Packages, AVAudioEngine, Accelerate/vDSP, Firebase Cloud Functions (TypeScript), Firestore, XCTest, XCUITest

**Design doc:** `docs/plans/2026-02-20-strumly-design.md`

---

## Task 1: Xcode Project Scaffolding

**Files:**
- Create: `Strumly/Strumly.xcodeproj`
- Create: `Strumly/StrumlyApp/StrumlyApp.swift`
- Create: `Strumly/StrumlyApp/ContentView.swift`
- Create: `Strumly/StrumlyWatch/StrumlyWatchApp.swift`
- Create: `Strumly/Packages/StrumlyCore/Package.swift`
- Create: `Strumly/Packages/StrumlyUI/Package.swift`
- Create: `Strumly/Packages/StrumlyTuner/Package.swift`

**Step 1: Create Xcode multiplatform project**

Open Xcode > New Project > Multiplatform App. Name: `Strumly`. Organization: your org. Bundle ID: choose yours. Select SwiftUI. Set deployment targets: iOS 17, watchOS 10. Add a watchOS companion target named `StrumlyWatch`.

**Step 2: Create the three Swift packages**

In terminal from the `Strumly/` project root:

```bash
mkdir -p Packages/StrumlyCore/Sources/StrumlyCore
mkdir -p Packages/StrumlyCore/Tests/StrumlyCoreTests
mkdir -p Packages/StrumlyUI/Sources/StrumlyUI
mkdir -p Packages/StrumlyUI/Tests/StrumlyUITests
mkdir -p Packages/StrumlyTuner/Sources/StrumlyTuner
mkdir -p Packages/StrumlyTuner/Tests/StrumlyTunerTests
```

**Step 3: Write StrumlyCore Package.swift**

```swift
// Packages/StrumlyCore/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StrumlyCore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "StrumlyCore", targets: ["StrumlyCore"]),
    ],
    targets: [
        .target(name: "StrumlyCore"),
        .testTarget(name: "StrumlyCoreTests", dependencies: ["StrumlyCore"]),
    ]
)
```

**Step 4: Write StrumlyUI Package.swift**

```swift
// Packages/StrumlyUI/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StrumlyUI",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "StrumlyUI", targets: ["StrumlyUI"]),
    ],
    dependencies: [
        .package(path: "../StrumlyCore"),
    ],
    targets: [
        .target(name: "StrumlyUI", dependencies: ["StrumlyCore"]),
        .testTarget(name: "StrumlyUITests", dependencies: ["StrumlyUI"]),
    ]
)
```

**Step 5: Write StrumlyTuner Package.swift**

```swift
// Packages/StrumlyTuner/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StrumlyTuner",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "StrumlyTuner", targets: ["StrumlyTuner"]),
    ],
    targets: [
        .target(name: "StrumlyTuner"),
        .testTarget(name: "StrumlyTunerTests", dependencies: ["StrumlyTuner"]),
    ]
)
```

**Step 6: Add packages to Xcode project**

In Xcode: File > Add Package Dependencies > Add Local > select each package under `Packages/`. Add `StrumlyCore`, `StrumlyUI`, `StrumlyTuner` as dependencies to the iOS target. Add `StrumlyCore` and `StrumlyTuner` to the watchOS target.

**Step 7: Set up placeholder ContentView with tab bar**

```swift
// StrumlyApp/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Songs")
                .tabItem {
                    Label("Songs", systemImage: "music.note.list")
                }
            Text("Chords")
                .tabItem {
                    Label("Chords", systemImage: "guitars")
                }
            Text("Tuner")
                .tabItem {
                    Label("Tuner", systemImage: "tuningfork")
                }
        }
    }
}
```

**Step 8: Build and run**

Run: Cmd+B in Xcode for both iOS and watchOS targets.
Expected: Both targets compile. iOS shows tab bar with 3 placeholder tabs.

**Step 9: Commit**

```bash
git add -A
git commit -m "feat: scaffold Strumly Xcode project with Swift packages and tab navigation"
```

---

## Task 2: StrumlyCore — Music Theory Models

**Files:**
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Models/Note.swift`
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Models/MusicTheory.swift`
- Test: `Packages/StrumlyCore/Tests/StrumlyCoreTests/MusicTheoryTests.swift`

**Step 1: Write failing tests for Note enum and transposition**

```swift
// Packages/StrumlyCore/Tests/StrumlyCoreTests/MusicTheoryTests.swift
import XCTest
@testable import StrumlyCore

final class MusicTheoryTests: XCTestCase {

    func testNoteFromString() {
        XCTAssertEqual(Note(rawValue: "C"), .C)
        XCTAssertEqual(Note(rawValue: "F#"), .FSharp)
        XCTAssertEqual(Note(rawValue: "Bb"), .ASharp) // enharmonic
    }

    func testTransposeUp() {
        XCTAssertEqual(Note.C.transposed(by: 2), .D)
        XCTAssertEqual(Note.B.transposed(by: 1), .C)
        XCTAssertEqual(Note.G.transposed(by: 5), .C)
    }

    func testTransposeDown() {
        XCTAssertEqual(Note.D.transposed(by: -2), .C)
        XCTAssertEqual(Note.C.transposed(by: -1), .B)
    }

    func testTransposeChordString() {
        XCTAssertEqual(MusicTheory.transposeChord("Am", semitones: 2), "Bm")
        XCTAssertEqual(MusicTheory.transposeChord("C", semitones: 5), "F")
        XCTAssertEqual(MusicTheory.transposeChord("G7", semitones: 1), "G#7")
        XCTAssertEqual(MusicTheory.transposeChord("F#m7", semitones: -1), "Fm7")
    }

    func testFrequencyForNote() {
        XCTAssertEqual(MusicTheory.frequency(note: .A, octave: 4), 440.0, accuracy: 0.01)
        XCTAssertEqual(MusicTheory.frequency(note: .A, octave: 3), 220.0, accuracy: 0.01)
        XCTAssertEqual(MusicTheory.frequency(note: .C, octave: 4), 261.63, accuracy: 0.01)
    }

    func testNoteFromFrequency() {
        let result = MusicTheory.noteFromFrequency(440.0)
        XCTAssertEqual(result.note, .A)
        XCTAssertEqual(result.octave, 4)
        XCTAssertEqual(result.centsOff, 0.0, accuracy: 0.1)

        let result2 = MusicTheory.noteFromFrequency(445.0)
        XCTAssertEqual(result2.note, .A)
        XCTAssertEqual(result2.octave, 4)
        XCTAssertGreaterThan(result2.centsOff, 0) // sharp
    }

    func testGuitarStringFrequencies() {
        XCTAssertEqual(GuitarString.allCases.count, 6)
        XCTAssertEqual(GuitarString.lowE.note, .E)
        XCTAssertEqual(GuitarString.lowE.octave, 2)
        XCTAssertEqual(GuitarString.highE.note, .E)
        XCTAssertEqual(GuitarString.highE.octave, 4)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: FAIL — types not defined

**Step 3: Implement Note enum**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Models/Note.swift
import Foundation

public enum Note: String, CaseIterable, Codable, Sendable {
    case C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B

    public init?(rawValue: String) {
        switch rawValue {
        case "C": self = .C
        case "C#", "Db": self = .CSharp
        case "D": self = .D
        case "D#", "Eb": self = .DSharp
        case "E": self = .E
        case "F": self = .F
        case "F#", "Gb": self = .FSharp
        case "G": self = .G
        case "G#", "Ab": self = .GSharp
        case "A": self = .A
        case "A#", "Bb": self = .ASharp
        case "B": self = .B
        default: return nil
        }
    }

    public var displayName: String {
        switch self {
        case .C: return "C"
        case .CSharp: return "C#"
        case .D: return "D"
        case .DSharp: return "D#"
        case .E: return "E"
        case .F: return "F"
        case .FSharp: return "F#"
        case .G: return "G"
        case .GSharp: return "G#"
        case .A: return "A"
        case .ASharp: return "A#"
        case .B: return "B"
        }
    }

    public var semitoneIndex: Int {
        Self.allCases.firstIndex(of: self)!
    }

    public func transposed(by semitones: Int) -> Note {
        let count = Self.allCases.count
        let newIndex = ((semitoneIndex + semitones) % count + count) % count
        return Self.allCases[newIndex]
    }
}

public enum GuitarString: CaseIterable, Sendable {
    case lowE, A, D, G, B, highE

    public var note: Note {
        switch self {
        case .lowE: return .E
        case .A: return .A
        case .D: return .D
        case .G: return .G
        case .B: return .B
        case .highE: return .E
        }
    }

    public var octave: Int {
        switch self {
        case .lowE: return 2
        case .A: return 2
        case .D: return 3
        case .G: return 3
        case .B: return 3
        case .highE: return 4
        }
    }

    public var standardFrequency: Double {
        MusicTheory.frequency(note: note, octave: octave)
    }
}
```

**Step 4: Implement MusicTheory**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Models/MusicTheory.swift
import Foundation

public struct DetectedNote: Equatable, Sendable {
    public let note: Note
    public let octave: Int
    public let centsOff: Double
    public let frequency: Double

    public init(note: Note, octave: Int, centsOff: Double, frequency: Double) {
        self.note = note
        self.octave = octave
        self.centsOff = centsOff
        self.frequency = frequency
    }
}

public enum MusicTheory {
    private static let a4Frequency: Double = 440.0
    private static let a4Semitone: Int = 57 // A4 is semitone 57 from C0

    public static func frequency(note: Note, octave: Int) -> Double {
        let semitone = octave * 12 + note.semitoneIndex
        let semitonesFromA4 = Double(semitone - a4Semitone)
        return a4Frequency * pow(2.0, semitonesFromA4 / 12.0)
    }

    public static func noteFromFrequency(_ freq: Double) -> DetectedNote {
        let semitonesFromA4 = 12.0 * log2(freq / a4Frequency)
        let roundedSemitone = Int(round(semitonesFromA4))
        let centsOff = (semitonesFromA4 - Double(roundedSemitone)) * 100.0

        let absoluteSemitone = roundedSemitone + a4Semitone
        let octave = absoluteSemitone / 12
        let noteIndex = ((absoluteSemitone % 12) + 12) % 12
        let note = Note.allCases[noteIndex]

        return DetectedNote(note: note, octave: octave, centsOff: centsOff, frequency: freq)
    }

    public static func transposeChord(_ chord: String, semitones: Int) -> String {
        guard !chord.isEmpty else { return chord }

        var rootLength = 1
        if chord.count > 1 {
            let second = chord[chord.index(after: chord.startIndex)]
            if second == "#" || second == "b" {
                rootLength = 2
            }
        }

        let rootString = String(chord.prefix(rootLength))
        let suffix = String(chord.dropFirst(rootLength))

        guard let rootNote = Note(rawValue: rootString) else { return chord }
        let transposed = rootNote.transposed(by: semitones)
        return transposed.displayName + suffix
    }

    public static func closestGuitarString(to frequency: Double) -> GuitarString {
        GuitarString.allCases.min(by: {
            abs(log2(frequency / $0.standardFrequency)) < abs(log2(frequency / $1.standardFrequency))
        })!
    }
}
```

**Step 5: Run tests to verify they pass**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add Packages/StrumlyCore/Sources Packages/StrumlyCore/Tests
git commit -m "feat: add Note enum, MusicTheory with transposition and frequency mapping"
```

---

## Task 3: StrumlyCore — Song & Chord Data Models

**Files:**
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Models/Song.swift`
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Models/Chord.swift`
- Test: `Packages/StrumlyCore/Tests/StrumlyCoreTests/ModelDecodingTests.swift`

**Step 1: Write failing tests for JSON decoding**

```swift
// Packages/StrumlyCore/Tests/StrumlyCoreTests/ModelDecodingTests.swift
import XCTest
@testable import StrumlyCore

final class ModelDecodingTests: XCTestCase {

    func testDecodeSong() throws {
        let json = """
        {
            "id": "1",
            "title": "Wonderwall",
            "artist": "Oasis",
            "key": "Em",
            "capoFret": 2,
            "coverImageURL": null,
            "playCount": 1500,
            "genre": "Rock",
            "sections": [{
                "type": "verse",
                "lines": [{
                    "lyrics": "Today is gonna be the day",
                    "chords": [{"chord": "Em7", "offset": 0}, {"chord": "G", "offset": 15}]
                }]
            }]
        }
        """.data(using: .utf8)!

        let song = try JSONDecoder().decode(Song.self, from: json)
        XCTAssertEqual(song.id, "1")
        XCTAssertEqual(song.title, "Wonderwall")
        XCTAssertEqual(song.artist, "Oasis")
        XCTAssertEqual(song.key, "Em")
        XCTAssertEqual(song.capoFret, 2)
        XCTAssertEqual(song.playCount, 1500)
        XCTAssertEqual(song.sections.count, 1)
        XCTAssertEqual(song.sections[0].lines[0].chords.count, 2)
        XCTAssertEqual(song.sections[0].lines[0].chords[0].chord, "Em7")
    }

    func testDecodeArtist() throws {
        let json = """
        {"id": "1", "name": "Oasis", "imageURL": null, "songCount": 25}
        """.data(using: .utf8)!

        let artist = try JSONDecoder().decode(Artist.self, from: json)
        XCTAssertEqual(artist.name, "Oasis")
        XCTAssertEqual(artist.songCount, 25)
    }

    func testDecodeChord() throws {
        let json = """
        {
            "id": "am",
            "name": "Am",
            "fullName": "A Minor",
            "category": "minor",
            "notes": ["A", "C", "E"],
            "voicings": [{
                "strings": [
                    {"fret": -1, "finger": null},
                    {"fret": 0, "finger": null},
                    {"fret": 2, "finger": 2},
                    {"fret": 2, "finger": 3},
                    {"fret": 1, "finger": 1},
                    {"fret": 0, "finger": null}
                ],
                "barres": null,
                "baseFret": 1
            }]
        }
        """.data(using: .utf8)!

        let chord = try JSONDecoder().decode(Chord.self, from: json)
        XCTAssertEqual(chord.name, "Am")
        XCTAssertEqual(chord.category, .minor)
        XCTAssertEqual(chord.voicings.count, 1)
        XCTAssertEqual(chord.voicings[0].strings.count, 6)
        XCTAssertEqual(chord.voicings[0].strings[0].fret, -1) // muted
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: FAIL — Song, Artist, Chord types not defined

**Step 3: Implement Song model**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Models/Song.swift
import Foundation

public struct Song: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let key: String
    public let capoFret: Int?
    public let coverImageURL: String?
    public let playCount: Int
    public let genre: String?
    public let sections: [SongSection]

    public init(id: String, title: String, artist: String, key: String, capoFret: Int?, coverImageURL: String?, playCount: Int, genre: String?, sections: [SongSection]) {
        self.id = id
        self.title = title
        self.artist = artist
        self.key = key
        self.capoFret = capoFret
        self.coverImageURL = coverImageURL
        self.playCount = playCount
        self.genre = genre
        self.sections = sections
    }
}

public struct SongSection: Codable, Sendable {
    public let type: String
    public let lines: [SongLine]
}

public struct SongLine: Codable, Sendable {
    public let lyrics: String
    public let chords: [ChordPosition]
}

public struct ChordPosition: Codable, Sendable {
    public let chord: String
    public let offset: Int
}

public struct Artist: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let imageURL: String?
    public let songCount: Int
}
```

**Step 4: Implement Chord model**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Models/Chord.swift
import Foundation

public struct Chord: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let fullName: String
    public let category: ChordCategory
    public let notes: [String]
    public let voicings: [Voicing]
}

public enum ChordCategory: String, Codable, CaseIterable, Sendable {
    case major, minor, seventh, majorSeventh, minorSeventh
    case suspended, diminished, augmented
}

public struct Voicing: Codable, Sendable {
    public let strings: [StringFret]
    public let barres: [Barre]?
    public let baseFret: Int
}

public struct StringFret: Codable, Sendable {
    public let fret: Int
    public let finger: Int?
}

public struct Barre: Codable, Sendable {
    public let fromString: Int
    public let toString: Int
    public let fret: Int
}
```

**Step 5: Run tests to verify they pass**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add Packages/StrumlyCore/Sources Packages/StrumlyCore/Tests
git commit -m "feat: add Song, Artist, and Chord data models with JSON decoding"
```

---

## Task 4: StrumlyCore — API Client

**Files:**
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Networking/StrumlyAPI.swift`
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Networking/APIError.swift`
- Test: `Packages/StrumlyCore/Tests/StrumlyCoreTests/StrumlyAPITests.swift`

**Step 1: Write failing tests using URLProtocol mock**

```swift
// Packages/StrumlyCore/Tests/StrumlyCoreTests/StrumlyAPITests.swift
import XCTest
@testable import StrumlyCore

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
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

final class StrumlyAPITests: XCTestCase {
    var api: StrumlyAPI!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        api = StrumlyAPI(baseURL: URL(string: "https://example.com/api")!, session: session)
    }

    func testSearchSongs() async throws {
        let songsJSON = """
        [{"id":"1","title":"Test","artist":"Artist","key":"C","capoFret":null,"coverImageURL":null,"playCount":10,"genre":null,"sections":[]}]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("q=test"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, songsJSON)
        }

        let songs = try await api.searchSongs(query: "test")
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].title, "Test")
    }

    func testGetPopularSongs() async throws {
        let songsJSON = "[]".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("popular"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, songsJSON)
        }

        let songs = try await api.getPopularSongs(limit: 20)
        XCTAssertEqual(songs.count, 0)
    }

    func testGetSongDetail() async throws {
        let songJSON = """
        {"id":"1","title":"Test","artist":"Artist","key":"C","capoFret":null,"coverImageURL":null,"playCount":10,"genre":null,"sections":[]}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("songs/1"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, songJSON)
        }

        let song = try await api.getSong(id: "1")
        XCTAssertEqual(song.id, "1")
    }

    func testAPIErrorOnServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await api.searchSongs(query: "test")
            XCTFail("Should have thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .serverError(500))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: FAIL — StrumlyAPI and APIError not defined

**Step 3: Implement APIError**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Networking/APIError.swift
import Foundation

public enum APIError: Error, Equatable {
    case invalidURL
    case serverError(Int)
    case decodingError
    case networkError(String)
}
```

**Step 4: Implement StrumlyAPI**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Networking/StrumlyAPI.swift
import Foundation

public final class StrumlyAPI: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func searchSongs(query: String) async throws -> [Song] {
        var components = URLComponents(url: baseURL.appendingPathComponent("songs"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return try await fetch(components.url!)
    }

    public func getPopularSongs(limit: Int = 20) async throws -> [Song] {
        var components = URLComponents(url: baseURL.appendingPathComponent("songs/popular"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        return try await fetch(components.url!)
    }

    public func getSong(id: String) async throws -> Song {
        let url = baseURL.appendingPathComponent("songs/\(id)")
        return try await fetch(url)
    }

    public func getPopularArtists(limit: Int = 20) async throws -> [Artist] {
        var components = URLComponents(url: baseURL.appendingPathComponent("artists/popular"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        return try await fetch(components.url!)
    }

    public func getArtistSongs(artistId: String) async throws -> [Song] {
        let url = baseURL.appendingPathComponent("artists/\(artistId)/songs")
        return try await fetch(url)
    }

    public func recordPlay(songId: String) async throws {
        let url = baseURL.appendingPathComponent("songs/\(songId)/play")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.serverError(code)
        }
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
```

**Step 5: Run tests to verify they pass**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add Packages/StrumlyCore/Sources Packages/StrumlyCore/Tests
git commit -m "feat: add StrumlyAPI networking client with async/await"
```

---

## Task 5: StrumlyTuner — Pitch Detection Algorithm

**Files:**
- Create: `Packages/StrumlyTuner/Sources/StrumlyTuner/PitchDetector.swift`
- Test: `Packages/StrumlyTuner/Tests/StrumlyTunerTests/PitchDetectorTests.swift`

**Step 1: Write failing tests with synthetic sine wave signals**

```swift
// Packages/StrumlyTuner/Tests/StrumlyTunerTests/PitchDetectorTests.swift
import XCTest
@testable import StrumlyTuner

final class PitchDetectorTests: XCTestCase {

    let sampleRate: Double = 44100
    let bufferSize: Int = 4096

    /// Generate a pure sine wave buffer at a given frequency
    func sineWave(frequency: Double) -> [Float] {
        (0..<bufferSize).map { i in
            Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate))
        }
    }

    func testDetect440Hz() {
        let buffer = sineWave(frequency: 440.0)
        let detector = PitchDetector(sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 440.0, accuracy: 2.0)
    }

    func testDetect330Hz() {
        let buffer = sineWave(frequency: 329.63) // E4
        let detector = PitchDetector(sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 329.63, accuracy: 2.0)
    }

    func testDetect82Hz() {
        let buffer = sineWave(frequency: 82.41) // low E2
        let detector = PitchDetector(sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 82.41, accuracy: 2.0)
    }

    func testSilenceReturnsNil() {
        let buffer = [Float](repeating: 0.0, count: bufferSize)
        let detector = PitchDetector(sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer)
        XCTAssertNil(result)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/StrumlyTuner`
Expected: FAIL — PitchDetector not defined

**Step 3: Implement PitchDetector using autocorrelation**

```swift
// Packages/StrumlyTuner/Sources/StrumlyTuner/PitchDetector.swift
import Foundation
import Accelerate

public final class PitchDetector: Sendable {
    private let sampleRate: Double
    private let minFrequency: Double
    private let maxFrequency: Double

    public init(sampleRate: Double = 44100, minFrequency: Double = 60, maxFrequency: Double = 1200) {
        self.sampleRate = sampleRate
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
    }

    /// Detect the fundamental pitch frequency from an audio buffer.
    /// Returns nil if the signal is too quiet or no clear pitch is detected.
    public func detectPitch(buffer: [Float]) -> Double? {
        // Check if signal is loud enough (RMS threshold)
        var rms: Float = 0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(buffer.count))
        guard rms > 0.01 else { return nil }

        let n = buffer.count
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = min(Int(sampleRate / minFrequency), n - 1)

        guard minLag < maxLag else { return nil }

        // Normalized autocorrelation
        var autocorrelation = [Float](repeating: 0, count: maxLag + 1)
        for lag in minLag...maxLag {
            var sum: Float = 0
            vDSP_dotpr(buffer, 1,
                       Array(buffer[lag..<n]), 1,
                       &sum,
                       vDSP_Length(n - lag))
            autocorrelation[lag] = sum
        }

        // Find the peak in the autocorrelation
        var bestLag = minLag
        var bestValue: Float = autocorrelation[minLag]
        for lag in (minLag + 1)...maxLag {
            if autocorrelation[lag] > bestValue {
                bestValue = autocorrelation[lag]
                bestLag = lag
            }
        }

        // Parabolic interpolation for sub-sample accuracy
        let lagRefined: Double
        if bestLag > minLag && bestLag < maxLag {
            let alpha = autocorrelation[bestLag - 1]
            let beta = autocorrelation[bestLag]
            let gamma = autocorrelation[bestLag + 1]
            let denominator = alpha - 2.0 * beta + gamma
            if abs(denominator) > 1e-10 {
                let correction = Double(0.5 * (alpha - gamma)) / Double(denominator)
                lagRefined = Double(bestLag) + correction
            } else {
                lagRefined = Double(bestLag)
            }
        } else {
            lagRefined = Double(bestLag)
        }

        let frequency = sampleRate / lagRefined
        guard frequency >= minFrequency && frequency <= maxFrequency else { return nil }

        return frequency
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/StrumlyTuner`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Packages/StrumlyTuner/Sources Packages/StrumlyTuner/Tests
git commit -m "feat: add autocorrelation-based PitchDetector with Accelerate"
```

---

## Task 6: StrumlyTuner — Audio Engine Manager

**Files:**
- Create: `Packages/StrumlyTuner/Sources/StrumlyTuner/AudioEngine.swift`
- Create: `Packages/StrumlyTuner/Sources/StrumlyTuner/TunerState.swift`

**Step 1: Implement TunerState observable model**

```swift
// Packages/StrumlyTuner/Sources/StrumlyTuner/TunerState.swift
import Foundation

@MainActor
public final class TunerState: ObservableObject {
    @Published public var isActive: Bool = false
    @Published public var detectedFrequency: Double?
    @Published public var detectedNote: String = "—"
    @Published public var detectedOctave: Int = 0
    @Published public var centsOff: Double = 0.0
    @Published public var closestStringName: String = ""

    public init() {}

    public func update(frequency: Double?, note: String, octave: Int, cents: Double, stringName: String) {
        self.detectedFrequency = frequency
        self.detectedNote = note
        self.detectedOctave = octave
        self.centsOff = cents
        self.closestStringName = stringName
    }

    public func reset() {
        detectedFrequency = nil
        detectedNote = "—"
        detectedOctave = 0
        centsOff = 0.0
        closestStringName = ""
    }
}
```

**Step 2: Implement AudioEngine (wraps AVAudioEngine)**

```swift
// Packages/StrumlyTuner/Sources/StrumlyTuner/AudioEngine.swift
#if canImport(AVFAudio)
import AVFAudio
import Foundation

public final class AudioEngine {
    private let engine = AVAudioEngine()
    private let pitchDetector: PitchDetector
    private let bufferSize: AVAudioFrameCount = 4096
    public var onPitchDetected: ((Double?) -> Void)?

    public init(pitchDetector: PitchDetector = PitchDetector()) {
        self.pitchDetector = pitchDetector
    }

    public func start() throws {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self, let channelData = buffer.floatChannelData else { return }
            let frames = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frames))
            let frequency = self.pitchDetector.detectPitch(buffer: samples)
            self.onPitchDetected?(frequency)
        }

        engine.prepare()
        try engine.start()
    }

    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}
#endif
```

**Step 3: Build to verify compilation**

Run: Build both iOS and watchOS targets in Xcode (Cmd+B).
Expected: Compiles without errors.

**Step 4: Commit**

```bash
git add Packages/StrumlyTuner/Sources
git commit -m "feat: add AudioEngine and TunerState for real-time pitch detection"
```

---

## Task 7: StrumlyCore — Chord Data Loader

**Files:**
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Data/ChordDataLoader.swift`
- Create: `Packages/StrumlyCore/Sources/StrumlyCore/Resources/chords.json` (starter data)
- Test: `Packages/StrumlyCore/Tests/StrumlyCoreTests/ChordDataLoaderTests.swift`

**Step 1: Write failing test**

```swift
// Packages/StrumlyCore/Tests/StrumlyCoreTests/ChordDataLoaderTests.swift
import XCTest
@testable import StrumlyCore

final class ChordDataLoaderTests: XCTestCase {

    func testLoadChordsFromBundle() throws {
        let chords = try ChordDataLoader.loadChords()
        XCTAssertFalse(chords.isEmpty)
    }

    func testFindChordByName() throws {
        let chords = try ChordDataLoader.loadChords()
        let am = chords.first(where: { $0.name == "Am" })
        XCTAssertNotNil(am)
        XCTAssertEqual(am?.category, .minor)
    }

    func testFilterChordsByCategory() throws {
        let chords = try ChordDataLoader.loadChords()
        let majors = chords.filter { $0.category == .major }
        XCTAssertFalse(majors.isEmpty)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: FAIL — ChordDataLoader not defined

**Step 3: Create starter chords.json**

Create `Packages/StrumlyCore/Sources/StrumlyCore/Resources/chords.json` with at least 12 basic chords (C, D, E, F, G, A, Am, Dm, Em, B7, G7, D7). Full file content is large — start with a representative set covering each ChordCategory and expand later.

```json
[
  {
    "id": "c", "name": "C", "fullName": "C Major", "category": "major",
    "notes": ["C", "E", "G"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":3,"finger":3},{"fret":2,"finger":2},{"fret":0,"finger":null},{"fret":1,"finger":1},{"fret":0,"finger":null}],"barres":null,"baseFret":1}]
  },
  {
    "id": "d", "name": "D", "fullName": "D Major", "category": "major",
    "notes": ["D", "F#", "A"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":-1,"finger":null},{"fret":0,"finger":null},{"fret":2,"finger":1},{"fret":3,"finger":3},{"fret":2,"finger":2}],"barres":null,"baseFret":1}]
  },
  {
    "id": "e", "name": "E", "fullName": "E Major", "category": "major",
    "notes": ["E", "G#", "B"],
    "voicings": [{"strings": [{"fret":0,"finger":null},{"fret":2,"finger":2},{"fret":2,"finger":3},{"fret":1,"finger":1},{"fret":0,"finger":null},{"fret":0,"finger":null}],"barres":null,"baseFret":1}]
  },
  {
    "id": "g", "name": "G", "fullName": "G Major", "category": "major",
    "notes": ["G", "B", "D"],
    "voicings": [{"strings": [{"fret":3,"finger":2},{"fret":2,"finger":1},{"fret":0,"finger":null},{"fret":0,"finger":null},{"fret":0,"finger":null},{"fret":3,"finger":3}],"barres":null,"baseFret":1}]
  },
  {
    "id": "a", "name": "A", "fullName": "A Major", "category": "major",
    "notes": ["A", "C#", "E"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":0,"finger":null},{"fret":2,"finger":1},{"fret":2,"finger":2},{"fret":2,"finger":3},{"fret":0,"finger":null}],"barres":null,"baseFret":1}]
  },
  {
    "id": "f", "name": "F", "fullName": "F Major", "category": "major",
    "notes": ["F", "A", "C"],
    "voicings": [{"strings": [{"fret":1,"finger":1},{"fret":3,"finger":3},{"fret":3,"finger":4},{"fret":2,"finger":2},{"fret":1,"finger":1},{"fret":1,"finger":1}],"barres":[{"fromString":0,"toString":5,"fret":1}],"baseFret":1}]
  },
  {
    "id": "am", "name": "Am", "fullName": "A Minor", "category": "minor",
    "notes": ["A", "C", "E"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":0,"finger":null},{"fret":2,"finger":2},{"fret":2,"finger":3},{"fret":1,"finger":1},{"fret":0,"finger":null}],"barres":null,"baseFret":1}]
  },
  {
    "id": "dm", "name": "Dm", "fullName": "D Minor", "category": "minor",
    "notes": ["D", "F", "A"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":-1,"finger":null},{"fret":0,"finger":null},{"fret":2,"finger":2},{"fret":3,"finger":3},{"fret":1,"finger":1}],"barres":null,"baseFret":1}]
  },
  {
    "id": "em", "name": "Em", "fullName": "E Minor", "category": "minor",
    "notes": ["E", "G", "B"],
    "voicings": [{"strings": [{"fret":0,"finger":null},{"fret":2,"finger":2},{"fret":2,"finger":3},{"fret":0,"finger":null},{"fret":0,"finger":null},{"fret":0,"finger":null}],"barres":null,"baseFret":1}]
  },
  {
    "id": "b7", "name": "B7", "fullName": "B Dominant 7th", "category": "seventh",
    "notes": ["B", "D#", "F#", "A"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":2,"finger":1},{"fret":1,"finger":1},{"fret":2,"finger":2},{"fret":0,"finger":null},{"fret":2,"finger":3}],"barres":null,"baseFret":1}]
  },
  {
    "id": "g7", "name": "G7", "fullName": "G Dominant 7th", "category": "seventh",
    "notes": ["G", "B", "D", "F"],
    "voicings": [{"strings": [{"fret":3,"finger":3},{"fret":2,"finger":2},{"fret":0,"finger":null},{"fret":0,"finger":null},{"fret":0,"finger":null},{"fret":1,"finger":1}],"barres":null,"baseFret":1}]
  },
  {
    "id": "d7", "name": "D7", "fullName": "D Dominant 7th", "category": "seventh",
    "notes": ["D", "F#", "A", "C"],
    "voicings": [{"strings": [{"fret":-1,"finger":null},{"fret":-1,"finger":null},{"fret":0,"finger":null},{"fret":2,"finger":2},{"fret":1,"finger":1},{"fret":2,"finger":3}],"barres":null,"baseFret":1}]
  }
]
```

**Step 4: Implement ChordDataLoader**

```swift
// Packages/StrumlyCore/Sources/StrumlyCore/Data/ChordDataLoader.swift
import Foundation

public enum ChordDataLoader {
    public static func loadChords(from bundle: Bundle = .module) throws -> [Chord] {
        guard let url = bundle.url(forResource: "chords", withExtension: "json") else {
            throw ChordDataError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Chord].self, from: data)
    }
}

public enum ChordDataError: Error {
    case fileNotFound
}
```

**Note:** Update `Package.swift` for StrumlyCore to include `resources`:

```swift
.target(name: "StrumlyCore", resources: [.process("Resources")]),
```

**Step 5: Run tests to verify they pass**

Run: `swift test --package-path Packages/StrumlyCore`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add Packages/StrumlyCore
git commit -m "feat: add ChordDataLoader with bundled chord JSON data"
```

---

## Task 8: StrumlyUI — Chord Diagram View

**Files:**
- Create: `Packages/StrumlyUI/Sources/StrumlyUI/ChordDiagramView.swift`
- Test: Snapshot tests added later; verify via Xcode preview for now

**Step 1: Implement ChordDiagramView**

This is a SwiftUI `Canvas`-based view that draws a guitar fretboard with finger positions, open/muted markers, barre indicators, and fret numbers.

```swift
// Packages/StrumlyUI/Sources/StrumlyUI/ChordDiagramView.swift
import SwiftUI
import StrumlyCore

public struct ChordDiagramView: View {
    let voicing: Voicing
    let chordName: String
    let fretCount: Int

    public init(voicing: Voicing, chordName: String, fretCount: Int = 4) {
        self.voicing = voicing
        self.chordName = chordName
        self.fretCount = fretCount
    }

    public var body: some View {
        Canvas { context, size in
            let stringCount = 6
            let topPadding: CGFloat = 30
            let bottomPadding: CGFloat = 10
            let sidePadding: CGFloat = 30
            let stringSpacing = (size.width - 2 * sidePadding) / CGFloat(stringCount - 1)
            let fretSpacing = (size.height - topPadding - bottomPadding) / CGFloat(fretCount)

            // Draw nut (thick line at top if baseFret == 1)
            if voicing.baseFret == 1 {
                let nutRect = CGRect(x: sidePadding, y: topPadding, width: size.width - 2 * sidePadding, height: 4)
                context.fill(Path(nutRect), with: .color(.primary))
            }

            // Draw fret lines
            for fret in 0...fretCount {
                let y = topPadding + CGFloat(fret) * fretSpacing
                var path = Path()
                path.move(to: CGPoint(x: sidePadding, y: y))
                path.addLine(to: CGPoint(x: size.width - sidePadding, y: y))
                context.stroke(path, with: .color(.gray), lineWidth: 1)
            }

            // Draw string lines
            for string in 0..<stringCount {
                let x = sidePadding + CGFloat(string) * stringSpacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: topPadding))
                path.addLine(to: CGPoint(x: x, y: size.height - bottomPadding))
                context.stroke(path, with: .color(.gray), lineWidth: 1)
            }

            // Draw barres
            if let barres = voicing.barres {
                for barre in barres {
                    let y = topPadding + (CGFloat(barre.fret) - 0.5) * fretSpacing
                    let x1 = sidePadding + CGFloat(barre.fromString) * stringSpacing
                    let x2 = sidePadding + CGFloat(barre.toString) * stringSpacing
                    let barreRect = CGRect(x: min(x1, x2), y: y - 6, width: abs(x2 - x1), height: 12)
                    context.fill(Path(roundedRect: barreRect, cornerRadius: 6), with: .color(.primary))
                }
            }

            // Draw finger positions and open/muted markers
            let dotRadius: CGFloat = 10
            for (stringIndex, stringFret) in voicing.strings.enumerated() {
                let x = sidePadding + CGFloat(stringIndex) * stringSpacing

                if stringFret.fret == -1 {
                    // Muted: draw X above nut
                    let text = Text("X").font(.system(size: 12, weight: .bold))
                    context.draw(text, at: CGPoint(x: x, y: topPadding - 14))
                } else if stringFret.fret == 0 {
                    // Open: draw O above nut
                    let text = Text("O").font(.system(size: 12, weight: .bold))
                    context.draw(text, at: CGPoint(x: x, y: topPadding - 14))
                } else {
                    // Finger position dot
                    let y = topPadding + (CGFloat(stringFret.fret) - 0.5) * fretSpacing
                    let dotRect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                    context.fill(Path(ellipseIn: dotRect), with: .color(.primary))

                    // Finger number
                    if let finger = stringFret.finger {
                        let text = Text("\(finger)").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        context.draw(text, at: CGPoint(x: x, y: y))
                    }
                }
            }

            // Base fret label (if not open position)
            if voicing.baseFret > 1 {
                let text = Text("\(voicing.baseFret)fr").font(.system(size: 11))
                context.draw(text, at: CGPoint(x: sidePadding - 18, y: topPadding + fretSpacing * 0.5))
            }
        }
        .frame(width: 160, height: 200)
    }
}
```

**Step 2: Add a SwiftUI preview**

```swift
#Preview {
    // Am chord
    ChordDiagramView(
        voicing: Voicing(
            strings: [
                StringFret(fret: -1, finger: nil),
                StringFret(fret: 0, finger: nil),
                StringFret(fret: 2, finger: 2),
                StringFret(fret: 2, finger: 3),
                StringFret(fret: 1, finger: 1),
                StringFret(fret: 0, finger: nil)
            ],
            barres: nil,
            baseFret: 1
        ),
        chordName: "Am"
    )
}
```

**Step 3: Verify in Xcode preview**

Open the preview in Xcode canvas. Expected: A fretboard diagram showing Am chord.

**Step 4: Commit**

```bash
git add Packages/StrumlyUI/Sources
git commit -m "feat: add ChordDiagramView with Canvas-based fretboard rendering"
```

---

## Task 9: Chord Library UI Screens

**Files:**
- Create: `StrumlyApp/Views/Chords/ChordBrowserView.swift`
- Create: `StrumlyApp/Views/Chords/ChordCategoryView.swift`
- Create: `StrumlyApp/Views/Chords/ChordDetailView.swift`
- Create: `StrumlyApp/ViewModels/ChordViewModel.swift`

**Step 1: Implement ChordViewModel**

```swift
// StrumlyApp/ViewModels/ChordViewModel.swift
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

    var categories: [ChordCategory] {
        ChordCategory.allCases
    }

    func loadChords() {
        do {
            allChords = try ChordDataLoader.loadChords()
        } catch {
            allChords = []
        }
    }
}
```

**Step 2: Implement ChordBrowserView (grid of categories + search)**

```swift
// StrumlyApp/Views/Chords/ChordBrowserView.swift
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
                            NavigationLink(destination: ChordCategoryView(category: category, chords: viewModel.allChords.filter { $0.category == category })) {
                                Text(category.rawValue.capitalized)
                            }
                        }
                    }
                } else {
                    ForEach(viewModel.filteredChords) { chord in
                        NavigationLink(destination: ChordDetailView(chord: chord)) {
                            VStack(alignment: .leading) {
                                Text(chord.name).font(.headline)
                                Text(chord.fullName).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search chords")
            .navigationTitle("Chords")
            .onAppear { viewModel.loadChords() }
        }
    }
}
```

**Step 3: Implement ChordCategoryView**

```swift
// StrumlyApp/Views/Chords/ChordCategoryView.swift
import SwiftUI
import StrumlyCore

struct ChordCategoryView: View {
    let category: ChordCategory
    let chords: [Chord]

    var body: some View {
        List(chords) { chord in
            NavigationLink(destination: ChordDetailView(chord: chord)) {
                VStack(alignment: .leading) {
                    Text(chord.name).font(.headline)
                    Text(chord.fullName).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(category.rawValue.capitalized)
    }
}
```

**Step 4: Implement ChordDetailView**

```swift
// StrumlyApp/Views/Chords/ChordDetailView.swift
import SwiftUI
import StrumlyCore
import StrumlyUI

struct ChordDetailView: View {
    let chord: Chord
    @State private var selectedVoicingIndex = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(chord.name)
                    .font(.largeTitle.bold())
                Text(chord.fullName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Notes: \(chord.notes.joined(separator: " "))")
                    .font(.subheadline)

                if !chord.voicings.isEmpty {
                    ChordDiagramView(
                        voicing: chord.voicings[selectedVoicingIndex],
                        chordName: chord.name
                    )
                    .padding()

                    if chord.voicings.count > 1 {
                        Picker("Voicing", selection: $selectedVoicingIndex) {
                            ForEach(0..<chord.voicings.count, id: \.self) { i in
                                Text("Position \(i + 1)").tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(chord.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Step 5: Wire up the Chords tab in ContentView**

Replace the placeholder `Text("Chords")` in ContentView with `ChordBrowserView()`.

**Step 6: Build and run, verify chord browsing works**

Run: Cmd+R in Xcode.
Expected: Chords tab shows categories, tapping shows chord list, tapping shows detail with fretboard diagram.

**Step 7: Commit**

```bash
git add StrumlyApp/Views StrumlyApp/ViewModels StrumlyApp/ContentView.swift
git commit -m "feat: add Chord Library with browser, category, and detail views"
```

---

## Task 10: Songbook UI — Song List (Apple Music-style)

**Files:**
- Create: `StrumlyApp/Views/Songs/SongListView.swift`
- Create: `StrumlyApp/Views/Songs/SongCardView.swift`
- Create: `StrumlyApp/ViewModels/SongViewModel.swift`

**Step 1: Implement SongViewModel**

```swift
// StrumlyApp/ViewModels/SongViewModel.swift
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

    init(api: StrumlyAPI) {
        self.api = api
    }

    func loadHome() async {
        do {
            async let popular = api.getPopularSongs(limit: 20)
            async let artists = api.getPopularArtists(limit: 20)
            self.popularSongs = try await popular
            self.popularArtists = try await artists
            self.recentSongs = loadRecentFromDisk()
        } catch {
            self.errorMessage = "Failed to load songs. Pull to retry."
        }
    }

    func search() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            searchResults = try await api.searchSongs(query: searchText)
        } catch {
            errorMessage = "Search failed. Try again."
        }
        isSearching = false
    }

    func recordPlay(song: Song) {
        saveRecentToDisk(song)
        Task { try? await api.recordPlay(songId: song.id) }
    }

    // MARK: - Local recent songs (UserDefaults for MVP)
    private let recentKey = "recentSongIDs"
    private let maxRecent = 20

    private func loadRecentFromDisk() -> [Song] {
        // For MVP, recent songs are tracked by ID in UserDefaults
        // Full song objects come from the popular songs list or search cache
        return []
    }

    private func saveRecentToDisk(_ song: Song) {
        var ids = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
        ids.removeAll { $0 == song.id }
        ids.insert(song.id, at: 0)
        if ids.count > maxRecent { ids = Array(ids.prefix(maxRecent)) }
        UserDefaults.standard.set(ids, forKey: recentKey)
    }
}
```

**Step 2: Implement SongCardView (horizontal scroll card)**

```swift
// StrumlyApp/Views/Songs/SongCardView.swift
import SwiftUI
import StrumlyCore

struct SongCardView: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
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

struct ArtistCardView: View {
    let artist: Artist

    var body: some View {
        VStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            Text(artist.name)
                .font(.subheadline)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}
```

**Step 3: Implement SongListView (Apple Music-style)**

```swift
// StrumlyApp/Views/Songs/SongListView.swift
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
                if !viewModel.searchText.isEmpty {
                    searchResultsList
                } else {
                    homeContent
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Songs, artists")
            .onChange(of: viewModel.searchText) {
                Task { await viewModel.search() }
            }
            .navigationTitle("Songs")
            .task { await viewModel.loadHome() }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !viewModel.recentSongs.isEmpty {
                    sectionHeader("Recently Played")
                    horizontalSongScroll(viewModel.recentSongs)
                }

                if !viewModel.popularSongs.isEmpty {
                    sectionHeader("Most Popular")
                    horizontalSongScroll(viewModel.popularSongs)
                }

                if !viewModel.popularArtists.isEmpty {
                    sectionHeader("Popular Artists")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.popularArtists) { artist in
                                ArtistCardView(artist: artist)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .padding(.horizontal)
    }

    private func horizontalSongScroll(_ songs: [Song]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(songs) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        SongCardView(song: song)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var searchResultsList: some View {
        if viewModel.isSearching {
            ProgressView()
        } else if viewModel.searchResults.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List(viewModel.searchResults) { song in
                NavigationLink(destination: SongDetailView(song: song)) {
                    VStack(alignment: .leading) {
                        Text(song.title).font(.headline)
                        Text(song.artist).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
```

**Step 4: Wire up the Songs tab in ContentView**

Replace the placeholder Songs tab with `SongListView(api: /* your API instance */)`.

**Step 5: Build and verify**

Run: Cmd+B. Expected: Compiles. (Full functionality requires running backend.)

**Step 6: Commit**

```bash
git add StrumlyApp/Views/Songs StrumlyApp/ViewModels StrumlyApp/ContentView.swift
git commit -m "feat: add Apple Music-style song list with search, popular, and recent sections"
```

---

## Task 11: Songbook UI — Song Detail with Lyrics & Chords

**Files:**
- Create: `StrumlyApp/Views/Songs/SongDetailView.swift`
- Create: `StrumlyApp/Views/Songs/LyricsChordView.swift`

**Step 1: Implement LyricsChordView (renders one line with chords above)**

```swift
// StrumlyApp/Views/Songs/LyricsChordView.swift
import SwiftUI
import StrumlyCore

struct LyricsChordView: View {
    let line: SongLine
    let onChordTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Chord line
            chordRow
            // Lyrics line
            Text(line.lyrics)
                .font(.body)
        }
    }

    @ViewBuilder
    private var chordRow: some View {
        if !line.chords.isEmpty {
            HStack(spacing: 0) {
                let sorted = line.chords.sorted { $0.offset < $1.offset }
                ForEach(Array(sorted.enumerated()), id: \.offset) { index, chordPos in
                    let leadingSpaces = index == 0 ? chordPos.offset : max(0, chordPos.offset - (sorted[index - 1].offset + sorted[index - 1].chord.count))
                    Text(String(repeating: " ", count: leadingSpaces))
                        .font(.body.monospaced())
                    Text(chordPos.chord)
                        .font(.body.bold().monospaced())
                        .foregroundStyle(.blue)
                        .onTapGesture { onChordTap(chordPos.chord) }
                }
            }
        }
    }
}
```

**Step 2: Implement SongDetailView**

```swift
// StrumlyApp/Views/Songs/SongDetailView.swift
import SwiftUI
import StrumlyCore

struct SongDetailView: View {
    let song: Song
    @State private var transposeSemitones: Int = 0
    @State private var showChordPopup: Bool = false
    @State private var selectedChordName: String = ""
    @State private var autoScrollSpeed: Double = 0
    @State private var isAutoScrolling: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Song header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title).font(.title.bold())
                        Text(song.artist).font(.title3).foregroundStyle(.secondary)
                        HStack {
                            Text("Key: \(transposedKey)")
                            if let capo = song.capoFret, capo > 0 {
                                Text("Capo: Fret \(capo)")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Transpose controls
                    HStack {
                        Text("Transpose:")
                        Button("-") { transposeSemitones -= 1 }
                            .buttonStyle(.bordered)
                        Text("\(transposeSemitones > 0 ? "+" : "")\(transposeSemitones)")
                            .frame(width: 40)
                        Button("+") { transposeSemitones += 1 }
                            .buttonStyle(.bordered)
                        Spacer()
                    }

                    // Lyrics with chords
                    ForEach(Array(song.sections.enumerated()), id: \.offset) { sectionIndex, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.type.capitalized)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)

                            ForEach(Array(section.lines.enumerated()), id: \.offset) { lineIndex, line in
                                LyricsChordView(
                                    line: transposedLine(line),
                                    onChordTap: { chord in
                                        selectedChordName = chord
                                        showChordPopup = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChordPopup) {
            Text("Chord: \(selectedChordName)")
                .presentationDetents([.medium])
        }
    }

    private var transposedKey: String {
        MusicTheory.transposeChord(song.key, semitones: transposeSemitones)
    }

    private func transposedLine(_ line: SongLine) -> SongLine {
        guard transposeSemitones != 0 else { return line }
        let transposedChords = line.chords.map { pos in
            ChordPosition(
                chord: MusicTheory.transposeChord(pos.chord, semitones: transposeSemitones),
                offset: pos.offset
            )
        }
        return SongLine(lyrics: line.lyrics, chords: transposedChords)
    }
}
```

**Step 3: Build and verify**

Run: Cmd+B. Expected: Compiles. Song detail view shows lyrics with chords above, transpose buttons work.

**Step 4: Commit**

```bash
git add StrumlyApp/Views/Songs
git commit -m "feat: add song detail view with lyrics, chords, and transpose controls"
```

---

## Task 12: Tuner UI — iOS

**Files:**
- Create: `StrumlyApp/Views/Tuner/TunerView.swift`
- Create: `StrumlyApp/Views/Tuner/TunerGaugeView.swift`

**Step 1: Implement TunerGaugeView (needle indicator)**

```swift
// StrumlyApp/Views/Tuner/TunerGaugeView.swift
import SwiftUI

struct TunerGaugeView: View {
    let centsOff: Double // -50 to +50

    private var needleAngle: Double {
        // Map -50...+50 cents to -90...+90 degrees
        let clamped = max(-50, min(50, centsOff))
        return clamped * 1.8 // 90/50
    }

    private var tuningColor: Color {
        let absCents = abs(centsOff)
        if absCents <= 5 { return .green }
        if absCents <= 15 { return .yellow }
        return .red
    }

    var body: some View {
        ZStack {
            // Background arc
            Arc(startAngle: .degrees(-90), endAngle: .degrees(90))
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 200, height: 100)

            // Colored center zone
            Arc(startAngle: .degrees(-9), endAngle: .degrees(9))
                .stroke(Color.green.opacity(0.3), lineWidth: 8)
                .frame(width: 200, height: 100)

            // Needle
            Rectangle()
                .fill(tuningColor)
                .frame(width: 2, height: 80)
                .offset(y: -40)
                .rotationEffect(.degrees(needleAngle))
        }
        .frame(width: 220, height: 120)
    }
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                     radius: rect.width / 2,
                     startAngle: startAngle + .degrees(180),
                     endAngle: endAngle + .degrees(180),
                     clockwise: false)
        return path
    }
}
```

**Step 2: Implement TunerView**

```swift
// StrumlyApp/Views/Tuner/TunerView.swift
import SwiftUI
import StrumlyCore
import StrumlyTuner

struct TunerView: View {
    @StateObject private var tunerState = TunerState()
    @State private var audioEngine: AudioEngine?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Note display
                Text(tunerState.detectedNote)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                Text(tunerState.detectedOctave > 0 ? "Octave \(tunerState.detectedOctave)" : "")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Gauge
                TunerGaugeView(centsOff: tunerState.centsOff)

                // Frequency
                if let freq = tunerState.detectedFrequency {
                    Text(String(format: "%.1f Hz", freq))
                        .font(.headline.monospaced())
                }

                // Guitar strings
                HStack(spacing: 16) {
                    ForEach(GuitarString.allCases, id: \.self) { string in
                        Text("\(string.note.displayName)\(string.octave)")
                            .font(.caption.bold())
                            .padding(8)
                            .background(
                                tunerState.closestStringName == "\(string.note.displayName)\(string.octave)"
                                    ? Color.blue.opacity(0.2)
                                    : Color.gray.opacity(0.1)
                            )
                            .cornerRadius(8)
                    }
                }

                Spacer()

                // Start/Stop button
                Button(tunerState.isActive ? "Stop" : "Start Tuner") {
                    toggleTuner()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Tuner")
        }
    }

    private func toggleTuner() {
        if tunerState.isActive {
            audioEngine?.stop()
            tunerState.isActive = false
            tunerState.reset()
        } else {
            let engine = AudioEngine()
            engine.onPitchDetected = { frequency in
                Task { @MainActor in
                    guard let freq = frequency else {
                        tunerState.update(frequency: nil, note: "—", octave: 0, cents: 0, stringName: "")
                        return
                    }
                    let detected = MusicTheory.noteFromFrequency(freq)
                    let closest = MusicTheory.closestGuitarString(to: freq)
                    tunerState.update(
                        frequency: freq,
                        note: detected.note.displayName,
                        octave: detected.octave,
                        cents: detected.centsOff,
                        stringName: "\(closest.note.displayName)\(closest.octave)"
                    )
                }
            }
            do {
                try engine.start()
                audioEngine = engine
                tunerState.isActive = true
            } catch {
                tunerState.update(frequency: nil, note: "Mic Error", octave: 0, cents: 0, stringName: "")
            }
        }
    }
}
```

**Step 3: Wire up Tuner tab in ContentView**

Replace placeholder with `TunerView()`.

**Step 4: Build and run on device (microphone requires real device)**

Run: Cmd+R on physical device.
Expected: Tuner starts, detects pitch from microphone, shows note/gauge.

**Step 5: Add `NSMicrophoneUsageDescription` to Info.plist**

```
<key>NSMicrophoneUsageDescription</key>
<string>Strumly needs microphone access to tune your guitar.</string>
```

**Step 6: Commit**

```bash
git add StrumlyApp/Views/Tuner StrumlyApp/ContentView.swift StrumlyApp/Info.plist
git commit -m "feat: add chromatic tuner with real-time pitch detection and gauge UI"
```

---

## Task 13: Apple Watch — Tuner App

**Files:**
- Create: `StrumlyWatch/TunerWatchView.swift`
- Modify: `StrumlyWatch/StrumlyWatchApp.swift`

**Step 1: Implement simplified watch tuner view**

```swift
// StrumlyWatch/TunerWatchView.swift
import SwiftUI
import StrumlyCore
import StrumlyTuner

struct TunerWatchView: View {
    @StateObject private var tunerState = TunerState()
    @State private var audioEngine: AudioEngine?

    var body: some View {
        VStack(spacing: 8) {
            Text(tunerState.detectedNote)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tuningColor)

            if tunerState.centsOff > 2 {
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Sharp").font(.caption2)
            } else if tunerState.centsOff < -2 {
                Image(systemName: "arrow.up")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Flat").font(.caption2)
            } else if tunerState.isActive && tunerState.detectedFrequency != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("In Tune").font(.caption2)
            }

            Button(tunerState.isActive ? "Stop" : "Tune") {
                toggleTuner()
            }
        }
    }

    private var tuningColor: Color {
        guard tunerState.detectedFrequency != nil else { return .primary }
        return abs(tunerState.centsOff) <= 5 ? .green : .red
    }

    private func toggleTuner() {
        if tunerState.isActive {
            audioEngine?.stop()
            tunerState.isActive = false
            tunerState.reset()
        } else {
            let engine = AudioEngine()
            engine.onPitchDetected = { frequency in
                Task { @MainActor in
                    guard let freq = frequency else {
                        tunerState.update(frequency: nil, note: "—", octave: 0, cents: 0, stringName: "")
                        return
                    }
                    let detected = MusicTheory.noteFromFrequency(freq)
                    let closest = MusicTheory.closestGuitarString(to: freq)
                    tunerState.update(
                        frequency: freq,
                        note: detected.note.displayName,
                        octave: detected.octave,
                        cents: detected.centsOff,
                        stringName: "\(closest.note.displayName)\(closest.octave)"
                    )
                }
            }
            do {
                try engine.start()
                audioEngine = engine
                tunerState.isActive = true
            } catch {
                tunerState.update(frequency: nil, note: "Err", octave: 0, cents: 0, stringName: "")
            }
        }
    }
}
```

**Step 2: Update StrumlyWatchApp entry point**

```swift
// StrumlyWatch/StrumlyWatchApp.swift
import SwiftUI

@main
struct StrumlyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TunerWatchView()
        }
    }
}
```

**Step 3: Add microphone usage description to watchOS Info.plist**

**Step 4: Build and run on Apple Watch simulator/device**

Expected: Watch shows tuner with note name and directional indicators.

**Step 5: Commit**

```bash
git add StrumlyWatch
git commit -m "feat: add Apple Watch tuner companion app"
```

---

## Task 14: Firebase Backend

**Files:**
- Create: `Firebase/functions/src/index.ts`
- Create: `Firebase/functions/package.json`
- Create: `Firebase/firestore.rules`
- Create: `Firebase/firebase.json`

**Step 1: Initialize Firebase project**

```bash
cd Firebase
npm install -g firebase-tools
firebase init  # select Functions (TypeScript), Firestore, Hosting
```

**Step 2: Implement Cloud Functions API**

```typescript
// Firebase/functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const searchSongs = functions.https.onRequest(async (req, res) => {
  const query = (req.query.q as string || "").toLowerCase();
  if (!query) { res.json([]); return; }

  const terms = query.split(/\s+/);
  const snapshot = await db.collection("songs")
    .where("searchTerms", "array-contains-any", terms)
    .limit(30)
    .get();

  res.json(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
});

export const getPopularSongs = functions.https.onRequest(async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);
  const snapshot = await db.collection("songs")
    .orderBy("playCount", "desc")
    .limit(limit)
    .get();

  res.json(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
});

export const getSong = functions.https.onRequest(async (req, res) => {
  const id = req.path.split("/").pop();
  if (!id) { res.status(400).json({ error: "Missing song ID" }); return; }

  const doc = await db.collection("songs").doc(id).get();
  if (!doc.exists) { res.status(404).json({ error: "Song not found" }); return; }

  res.json({ id: doc.id, ...doc.data() });
});

export const getPopularArtists = functions.https.onRequest(async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);
  const snapshot = await db.collection("artists")
    .orderBy("songCount", "desc")
    .limit(limit)
    .get();

  res.json(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
});

export const getArtistSongs = functions.https.onRequest(async (req, res) => {
  const artistId = req.path.split("/")[2]; // /artists/{id}/songs
  if (!artistId) { res.status(400).json({ error: "Missing artist ID" }); return; }

  const snapshot = await db.collection("songs")
    .where("artistId", "==", artistId)
    .get();

  res.json(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
});

export const recordPlay = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") { res.status(405).send("Method not allowed"); return; }
  const id = req.path.split("/").pop();
  if (!id) { res.status(400).json({ error: "Missing song ID" }); return; }

  await db.collection("songs").doc(id).update({
    playCount: admin.firestore.FieldValue.increment(1),
  });

  res.json({ success: true });
});
```

**Step 3: Write Firestore rules**

```
// Firebase/firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /songs/{songId} {
      allow read: if true;
      allow write: if false; // admin-only writes
    }
    match /artists/{artistId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

**Step 4: Deploy and test**

```bash
cd Firebase
firebase deploy --only functions,firestore:rules
```

**Step 5: Seed test data**

Use Firebase console or a script to add a few test songs and artists to Firestore.

**Step 6: Commit**

```bash
git add Firebase
git commit -m "feat: add Firebase Cloud Functions API and Firestore rules"
```

---

## Task 15: Integration & Automated UI Tests

**Files:**
- Create: `StrumlyApp/StrumlyUITests/NavigationTests.swift`
- Create: `StrumlyApp/StrumlyUITests/ChordBrowserTests.swift`

**Step 1: Write UI test for tab navigation**

```swift
// StrumlyUITests/NavigationTests.swift
import XCTest

final class NavigationTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testTabNavigation() {
        XCTAssertTrue(app.tabBars.buttons["Songs"].exists)
        XCTAssertTrue(app.tabBars.buttons["Chords"].exists)
        XCTAssertTrue(app.tabBars.buttons["Tuner"].exists)

        app.tabBars.buttons["Chords"].tap()
        XCTAssertTrue(app.navigationBars["Chords"].exists)

        app.tabBars.buttons["Tuner"].tap()
        XCTAssertTrue(app.navigationBars["Tuner"].exists)

        app.tabBars.buttons["Songs"].tap()
        XCTAssertTrue(app.navigationBars["Songs"].exists)
    }
}
```

**Step 2: Write UI test for chord browsing**

```swift
// StrumlyUITests/ChordBrowserTests.swift
import XCTest

final class ChordBrowserTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testBrowseChordCategory() {
        app.tabBars.buttons["Chords"].tap()
        app.staticTexts["Major"].tap()
        XCTAssertTrue(app.navigationBars["Major"].waitForExistence(timeout: 2))
    }

    func testSearchChord() {
        app.tabBars.buttons["Chords"].tap()
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Am")
        XCTAssertTrue(app.staticTexts["Am"].waitForExistence(timeout: 2))
    }
}
```

**Step 3: Run UI tests**

Run: Cmd+U in Xcode.
Expected: All UI tests pass.

**Step 4: Commit**

```bash
git add StrumlyApp/StrumlyUITests
git commit -m "test: add automated UI tests for navigation and chord browsing"
```

---

## Summary of Implementation Order

| Task | What | Dependencies |
|------|------|-------------|
| 1 | Xcode project scaffolding | None |
| 2 | Music theory models (Note, MusicTheory) | Task 1 |
| 3 | Song & Chord data models | Task 1 |
| 4 | API client (StrumlyAPI) | Task 3 |
| 5 | Pitch detection algorithm | Task 1 |
| 6 | Audio engine manager | Task 5 |
| 7 | Chord data loader + JSON | Task 3 |
| 8 | Chord diagram view | Task 3 |
| 9 | Chord library UI screens | Tasks 7, 8 |
| 10 | Song list UI (Apple Music-style) | Task 4 |
| 11 | Song detail with lyrics/chords | Tasks 2, 10 |
| 12 | Tuner UI (iOS) | Tasks 2, 6 |
| 13 | Apple Watch tuner | Tasks 2, 6 |
| 14 | Firebase backend | None (parallel) |
| 15 | Automated UI tests | Tasks 9, 10, 12 |
