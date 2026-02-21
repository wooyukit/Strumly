# Strumly — Guitar Companion App Design

## Overview

Strumly is a guitar companion app for iPhone, iPad, and Apple Watch. It provides three core features for guitarists: a songbook with lyrics and chords, a chord library with fingering diagrams, and a microphone-based chromatic tuner.

## Platforms & Tech Stack

- **Platforms**: iPhone, iPad, Apple Watch
- **UI Framework**: SwiftUI (multiplatform)
- **Minimum versions**: iOS 17, watchOS 10
- **Backend**: Firebase (Cloud Functions + Firestore + Hosting)
- **Development approach**: Test-Driven Development (TDD) with automated regression tests

## App Structure & Navigation

Tab-based navigation with three tabs:

| Tab | SF Symbol | Purpose |
|-----|-----------|---------|
| Songs | `music.note.list` | Browse and search songbook |
| Chords | `guitars` | Search and browse chord library |
| Tuner | `tuningfork` | Chromatic tuner |

**iPad**: Same tab bar; Songs tab uses sidebar-detail split view.

**Apple Watch**: Tuner only — single-screen app showing detected note, frequency, and sharp/flat indicator.

## Project Structure

```
Strumly/
├── StrumlyApp/           # iOS app target
├── StrumlyWatch/         # watchOS app target
├── Packages/
│   ├── StrumlyCore/      # Shared models, networking, API client
│   ├── StrumlyUI/        # Shared SwiftUI components (chord diagrams, etc.)
│   └── StrumlyTuner/     # Audio/pitch detection logic (shared iOS + watchOS)
├── Firebase/             # Cloud Functions + Firestore rules
└── docs/
```

## Feature 1: Songbook

### Screen Flow

1. **Song List (Apple Music-style layout)**:
   - Search bar at top (search by song title or artist)
   - Recently Played — horizontal scroll row (stored locally on device)
   - Most Popular — horizontal scroll row (from server, by play count)
   - Popular Artists — horizontal scroll row of artist cards
   - Browse All — vertical list below featured sections

2. **Song Detail**:
   - Full lyrics with chord symbols inline above corresponding words
   - Transpose: change key up/down by semitone, all chords update
   - Capo mode: show capo position, display simplified chord shapes
   - Tap a chord: opens chord diagram popup (links to Chord Library)
   - Auto-scroll: adjustable speed for hands-free playing

### Data Models

```swift
struct Song: Codable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let key: String              // e.g., "C", "Am", "G"
    let capoFret: Int?
    let coverImageURL: String?
    let playCount: Int
    let genre: String?
    let sections: [Section]
}

struct Section: Codable {
    let type: String             // "verse", "chorus", "bridge", "intro", "outro"
    let lines: [Line]
}

struct Line: Codable {
    let lyrics: String
    let chords: [ChordPosition]
}

struct ChordPosition: Codable {
    let chord: String            // e.g., "Am7", "Cmaj"
    let offset: Int              // character position above the lyrics line
}

struct Artist: Codable, Identifiable {
    let id: String
    let name: String
    let imageURL: String?
    let songCount: Int
}
```

## Feature 2: Chord Library

### Screen Flow

1. **Chord Browser**: Grid of chord categories (Major, Minor, 7th, Maj7, Min7, Sus, Dim, Aug). Tap a category to see all chords in that family.
2. **Search**: Search bar to find any chord by name (e.g., "Am7", "Dsus4").
3. **Chord Detail**: Fingering diagram with alternative voicings and audio playback.

### Chord Detail View

- Guitar fretboard diagram with finger positions (numbered 1-4), open/muted string markers, barre indicators, fret numbers
- Chord name and constituent notes (e.g., "Am7 — A C E G")
- Alternative voicings (swipe to see different positions)
- Audio playback (tap to hear the chord strummed)

### Data Model

```swift
struct Chord: Codable, Identifiable {
    let id: String
    let name: String             // "Am7"
    let fullName: String         // "A Minor 7th"
    let category: ChordCategory
    let notes: [String]          // ["A", "C", "E", "G"]
    let voicings: [Voicing]
}

enum ChordCategory: String, Codable, CaseIterable {
    case major, minor, seventh, majorSeventh, minorSeventh
    case suspended, diminished, augmented
}

struct Voicing: Codable {
    let strings: [StringFret]    // 6 entries (low E to high E)
    let barres: [Barre]?
    let baseFret: Int            // 1 for open position
}

struct StringFret: Codable {
    let fret: Int                // 0 = open, -1 = muted
    let finger: Int?             // 1-4, nil if open/muted
}

struct Barre: Codable {
    let fromString: Int
    let toString: Int
    let fret: Int
}
```

**Data source**: Bundled as a local JSON file in the app (no server dependency). Approximately 100-200 common guitar chords.

## Feature 3: Tuner

### How It Works

1. User opens Tuner tab, grants microphone permission
2. Audio captured via `AVAudioEngine` (iOS) / `AVAudioSession` (watchOS)
3. Pitch detection using autocorrelation algorithm (Accelerate framework / `vDSP`)
4. Detected frequency mapped to nearest musical note
5. Real-time visual feedback

### Technical Specs

- Sample rate: 44100 Hz
- Buffer size: 4096 samples (~93ms latency)
- Reference pitch: A4 = 440 Hz
- Detection range: ~60 Hz (B1) to ~1200 Hz (D6)

### iOS Tuner UI

- Large note name in center (e.g., "A")
- Octave number below (e.g., "4")
- Frequency display (e.g., "440.0 Hz")
- Needle/gauge: -50 to +50 cents
  - Green: within ±5 cents (in tune)
  - Yellow: ±5-15 cents
  - Red: >±15 cents off
- Guitar string indicators at bottom: E2, A2, D3, G3, B3, E4 (highlights closest string)

### Apple Watch Tuner UI

- Note name, sharp/flat arrow indicator
- Green/red color for in-tune / out-of-tune
- No needle gauge — clear directional feedback only

### Shared Package

The `StrumlyTuner` Swift package contains all pitch detection logic, shared by iOS and watchOS targets.

## Backend Architecture

### Firebase Services

- **Firebase Hosting**: Serves the Cloud Functions API
- **Cloud Functions (Node.js/TypeScript)**: API endpoints
- **Firestore**: Song and artist data storage

### Firestore Collections

```
/songs/{songId}          — Song documents
/artists/{artistId}      — Artist documents
```

### Firestore Indexes

- `songs`: composite index on `playCount` (descending) for popular songs
- `songs`: `searchTerms` array field with lowercased tokenized title/artist words for search

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/songs?q={query}` | Search songs by title/artist |
| GET | `/songs/popular?limit=20` | Top songs by play count |
| GET | `/songs/{id}` | Full song with lyrics/chords |
| GET | `/artists/popular?limit=20` | Top artists |
| GET | `/artists/{id}/songs` | All songs by an artist |
| POST | `/songs/{id}/play` | Increment play count |

### iOS Networking

- `StrumlyAPI` client in the `StrumlyCore` package
- `URLSession` with `async/await`
- `URLCache` for song data caching

## Error Handling

- **Network errors**: Retry banner at top of screen (non-blocking), cached data remains available
- **Microphone permission denied**: Clear message with button to open Settings
- **No search results**: Friendly empty state ("No songs found. Try a different search.")
- **Audio detection failures**: Show "—" instead of flickering between notes

## Testing Strategy (TDD)

### Unit Tests
- Pitch detection algorithm accuracy
- Chord transposition logic
- Data model parsing (JSON decoding)
- API client request/response handling
- Search term tokenization

### UI Tests (Automated Regression)
- Tab navigation flow
- Song search and detail viewing
- Chord browser navigation
- Tuner screen microphone permission flow
- Transpose and capo functionality

### Snapshot Tests
- Chord diagram rendering consistency across voicings
- Tuner gauge rendering at various cent offsets

### Integration Tests
- API endpoint response validation
- Firestore query correctness

All tests run as part of CI to catch regressions automatically.
