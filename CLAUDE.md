# Strumly

Guitar companion app for iOS and Apple Watch.

## Project Structure

```
Strumly/
├── Strumly.xcodeproj/              # Xcode project (Xcode 26.3 beta)
├── Strumly/                        # iOS app target
│   ├── StrumlyApp.swift            # @main entry point
│   ├── ContentView.swift           # TabView (Songs, Chords, Tuner)
│   ├── ViewModels/                 # ChordViewModel, SongViewModel
│   └── Views/
│       ├── Chords/                 # ChordBrowserView, ChordCategoryView, ChordDetailView
│       ├── Songs/                  # SongListView, SongCardView, SongDetailView, LyricsChordView
│       └── Tuner/                  # TunerView, TunerGaugeView
├── StrumlyWatch Watch App/         # watchOS tuner app (embedded in iOS app)
├── Packages/
│   ├── StrumlyCore/                # Models, MusicTheory, API client, ChordDataLoader
│   ├── StrumlyTuner/               # PitchDetector, AudioEngine, TunerState
│   └── StrumlyUI/                  # ChordDiagramView (Canvas-based fretboard)
├── Firebase/                       # Cloud Functions (TypeScript) + Firestore rules
└── docs/plans/                     # Design doc and implementation plan
```

## Build & Test

- **iOS app**: Open `Strumly.xcodeproj`, select "Strumly" scheme, build for iOS device/simulator
- **Watch app**: Select "StrumlyWatch Watch App" scheme, build for watchOS
- **Package tests**: `cd Packages/StrumlyCore && swift test` (48 tests), `cd Packages/StrumlyTuner && swift test` (5 tests)
- **All package tests**: `for p in Packages/Strumly*; do (cd "$p" && swift test); done`

## Architecture

- **SwiftUI** with `@MainActor` isolation (Swift 6 concurrency via `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`** — must explicitly `import Combine` when using `ObservableObject`/`@Published`
- **Local Swift Packages** for modular code separation — iOS target depends on all 3; watch target depends on StrumlyCore + StrumlyTuner
- **PBXFileSystemSynchronizedRootGroup** — Xcode auto-syncs files in source directories; no manual pbxproj file list management needed
- **Pitch detection**: Autocorrelation via Apple Accelerate/vDSP with parabolic interpolation. A4=440Hz reference.
- **AudioEngine**: `#if canImport(AVFAudio)` guard — compiles on macOS for tests but only runs audio on device

## Conventions

- TDD with Swift Testing framework (`@Test`, `#expect`) for package tests, XCTest for UI tests
- ViewModels are `@MainActor final class` conforming to `ObservableObject`
- Views use `@StateObject` for owned ViewModels
- Music theory types: `Note` (enum, 12 semitones), `GuitarString` (enum, 6 strings), `Chord` (Hashable for NavigationLink)
- API client (`StrumlyAPI`) uses async/await with `URLSession`
- Firebase backend at `https://strumly-api.web.app/api`

## Key Files

| File | Purpose |
|------|---------|
| `Packages/StrumlyCore/Sources/StrumlyCore/Models/MusicTheory.swift` | Note detection, frequency math, guitar string matching |
| `Packages/StrumlyTuner/Sources/StrumlyTuner/PitchDetector.swift` | Autocorrelation pitch detection with Accelerate |
| `Packages/StrumlyTuner/Sources/StrumlyTuner/AudioEngine.swift` | AVAudioEngine microphone tap wrapper |
| `Packages/StrumlyCore/Sources/StrumlyCore/Data/ChordDataLoader.swift` | Loads chord data from bundled chords.json |
| `Packages/StrumlyUI/Sources/StrumlyUI/ChordDiagramView.swift` | Canvas-based guitar fretboard diagram renderer |
| `Firebase/functions/src/index.ts` | 6 Cloud Functions endpoints |
