# 🎸 Strumly

> **Your pocket guitar companion** — tune up, learn chords, and play along with your favourite songs. Built with SwiftUI for iOS & Apple Watch.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS_26+-blue?logo=apple" />
  <img src="https://img.shields.io/badge/Platform-watchOS_26+-purple?logo=apple" />
  <img src="https://img.shields.io/badge/Swift-6-orange?logo=swift" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎵 **Song Library** | Browse songs with lyrics & chords, transpose on the fly |
| 🎶 **Chord Browser** | Explore chords by category with interactive fretboard diagrams |
| 🎯 **Chromatic Tuner** | Real-time pitch detection powered by Apple Accelerate/vDSP |
| ⌚ **Watch Tuner** | Tune your guitar straight from your wrist — no phone needed |
| 🎨 **Dark Tuner UI** | Sleek mixtune-inspired design with guitar headstock visualisation |

## 🏗️ Architecture

```
Strumly/
├── 📱 Strumly/                        # iOS app
│   ├── StrumlyApp.swift               # @main entry point
│   ├── ContentView.swift              # TabView → Songs · Chords · Tuner
│   ├── ViewModels/                    # ChordViewModel, SongViewModel
│   └── Views/
│       ├── 🎵 Songs/                  # SongListView, SongDetailView, LyricsChordView
│       ├── 🎶 Chords/                 # ChordBrowserView, ChordCategoryView, ChordDetailView
│       └── 🎯 Tuner/                  # TunerView (dark UI + headstock), TunerGaugeView
├── ⌚ StrumlyWatch Watch App/          # watchOS tuner companion
├── 📦 Packages/
│   ├── StrumlyCore/                   # Models, MusicTheory, API client, ChordDataLoader
│   ├── StrumlyTuner/                  # PitchDetector, AudioEngine, TunerState
│   └── StrumlyUI/                     # ChordDiagramView (Canvas fretboard renderer)
├── 🔥 Firebase/                       # Cloud Functions (TypeScript) + Firestore rules
└── 📄 docs/plans/                     # Design docs & implementation plans
```

## 🚀 Getting Started

### Prerequisites

- **Xcode 26.3 beta** (or later)
- iOS 26.2+ device or simulator
- watchOS 26.2+ for the watch companion

### Build & Run

```bash
# 📱 iOS app — open in Xcode, select "Strumly" scheme, hit ⌘R
open Strumly.xcodeproj

# 🧪 Run package tests
cd Packages/StrumlyCore && swift test     # 48 tests
cd Packages/StrumlyTuner && swift test    # 5 tests

# 🧪 Run all package tests at once
for p in Packages/Strumly*; do (cd "$p" && swift test); done
```

## 🎯 Tuner — How It Works

The tuner is the heart of Strumly. Here's the signal pipeline:

```
🎤 Microphone
  → AVAudioEngine tap (1024-sample buffer)
    → PitchDetector (autocorrelation via Accelerate/vDSP)
      → Parabolic interpolation for sub-sample accuracy
        → MusicTheory.noteFromFrequency() → Note + Octave + Cents
          → MusicTheory.closestGuitarString() → Nearest string match
            → 🖥️ TunerView (real-time UI update)
```

| Component | What it does |
|-----------|-------------|
| 🔊 `AudioEngine` | Wraps `AVAudioEngine` with microphone tap, feeds PCM buffers |
| 🧮 `PitchDetector` | Autocorrelation + parabolic interpolation, A4 = 440 Hz reference |
| 🧠 `MusicTheory` | Frequency → note mapping, closest guitar string matching |
| 📊 `TunerState` | `@Published` observable state for SwiftUI binding |
| 🎨 `TunerView` | Dark UI with Canvas headstock, sliding gauge, string selector |

## 🎶 Chord Diagrams

Interactive fretboard diagrams rendered with **SwiftUI Canvas** — no images needed:

- 🎸 6-string standard guitar layout
- 🔴 Finger positions with fret numbers
- ❌ Muted strings & ⭕ open strings
- 📐 Auto-scaling to any view size

## ⚡ Tech Stack

| Layer | Technology |
|-------|-----------|
| 🖼️ UI | SwiftUI + Canvas |
| 🧵 Concurrency | Swift 6 strict concurrency (`@MainActor` isolation) |
| 🔊 Audio | AVAudioEngine + Accelerate/vDSP |
| 📦 Modularisation | Local Swift Packages (Core · Tuner · UI) |
| 🌐 Backend | Firebase Cloud Functions + Firestore |
| 🧪 Testing | Swift Testing (`@Test`, `#expect`) + XCTest |

## 🎮 Quick Guide

| Tab | What you can do |
|-----|----------------|
| 🎵 **Songs** | Browse → tap a song → see lyrics with chord markers → transpose ↕️ |
| 🎶 **Chords** | Pick a category → explore chords → view fretboard diagrams 🎸 |
| 🎯 **Tuner** | Tap **Start Tuning** → play a string → see note, cents, & closest string |
| ⌚ **Watch** | Open watch app → tap **Start** → tune on-the-go 🏃 |

## 🤝 Contributing

Contributions welcome! Some ideas:

- 🎸 Add more chord voicings & alternate tunings
- 🎵 Expand the song library
- 🌍 Localisation for more languages
- 🎨 Custom themes & colour schemes
- 🧪 More test coverage

## 📄 License

MIT © Vincent Woo

---

<p align="center">
  Made with 🎸 + ☕ + 🤖
  <br/>
  <sub>Built with Claude Code</sub>
</p>
