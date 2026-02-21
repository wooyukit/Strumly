//
//  ContentView.swift
//  StrumlyWatch Watch App
//
//  Created by WOO Yu Kit Vincent on 21/2/2026.
//

import Combine
import SwiftUI
import StrumlyCore
import StrumlyTuner

struct ContentView: View {
    @StateObject private var tunerState = TunerState()
    @State private var audioEngine: AudioEngine?

    var body: some View {
        VStack(spacing: 8) {
            // Note name
            Text(tunerState.detectedNote)
                .font(.system(size: 48, weight: .bold, design: .rounded))

            // Cents indicator
            HStack(spacing: 4) {
                Rectangle()
                    .fill(tunerState.centsOff < -5 ? .red : .gray.opacity(0.3))
                    .frame(width: 30, height: 4)
                    .clipShape(Capsule())

                Circle()
                    .fill(abs(tunerState.centsOff) <= 5 ? .green : .gray.opacity(0.3))
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(tunerState.centsOff > 5 ? .red : .gray.opacity(0.3))
                    .frame(width: 30, height: 4)
                    .clipShape(Capsule())
            }

            // Cents text
            if tunerState.detectedFrequency != nil {
                Text(centsText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Closest guitar string
            if !tunerState.closestStringName.isEmpty {
                Text(tunerState.closestStringName)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.blue))
                    .foregroundStyle(.white)
            }

            // Start/Stop button
            Button(tunerState.isActive ? "Stop" : "Start") {
                toggleTuner()
            }
            .buttonStyle(.borderedProminent)
            .tint(tunerState.isActive ? .red : .green)
        }
    }

    private var centsText: String {
        let cents = Int(tunerState.centsOff)
        if cents == 0 { return "In tune" }
        return cents > 0 ? "+\(cents)c sharp" : "\(cents)c flat"
    }

    private func toggleTuner() {
        if tunerState.isActive {
            audioEngine?.stop()
            audioEngine = nil
            tunerState.isActive = false
            tunerState.reset()
        } else {
            let engine = AudioEngine()
            engine.onPitchDetected = { frequency in
                Task { @MainActor in
                    if let freq = frequency {
                        let detected = MusicTheory.noteFromFrequency(freq)
                        let closest = MusicTheory.closestGuitarString(to: freq)
                        let stringLabel = "\(closest.note.displayName)\(closest.octave)"
                        tunerState.update(
                            frequency: freq,
                            note: detected.note.displayName,
                            octave: detected.octave,
                            cents: detected.centsOff,
                            stringName: stringLabel
                        )
                    } else {
                        tunerState.update(
                            frequency: nil,
                            note: "\u{2014}",
                            octave: 0,
                            cents: 0,
                            stringName: ""
                        )
                    }
                }
            }
            do {
                try engine.start()
                audioEngine = engine
                tunerState.isActive = true
            } catch {
                print("Failed to start audio engine: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
