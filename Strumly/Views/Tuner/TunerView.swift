import SwiftUI
import StrumlyCore
import StrumlyTuner

// MARK: - Guitar Headstock

/// A Canvas-drawn guitar headstock showing 6 tuning pegs and strings.
/// The closest detected string glows with an accent color.
private struct GuitarHeadstockView: View {
    let closestString: String
    let isActive: Bool

    private static let accent = Color(red: 0.0, green: 0.82, blue: 0.65)
    private static let labels = ["E2", "A2", "D3", "G3", "B3", "E4"]
    private static let stringThickness: [CGFloat] = [1.4, 1.2, 1.0, 0.9, 0.8, 0.7]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, cx = w / 2
            let neckW: CGFloat = 54
            let pegR: CGFloat = 9
            let pegDist: CGFloat = 34

            // Neck
            ctx.fill(
                RoundedRectangle(cornerRadius: 6)
                    .path(in: CGRect(x: cx - neckW / 2, y: 0, width: neckW, height: h)),
                with: .color(Color(white: 1, opacity: 0.03))
            )

            // Nut
            ctx.fill(
                RoundedRectangle(cornerRadius: 1.5)
                    .path(in: CGRect(x: cx - neckW / 2 - 3, y: h - 14, width: neckW + 6, height: 3)),
                with: .color(Color(white: 1, opacity: 0.12))
            )

            let stringGap = (neckW - 14) / 5
            let stringX0 = cx - (neckW - 14) / 2
            let pegYs: [CGFloat] = [h * 0.18, h * 0.40, h * 0.62]

            for i in 0..<6 {
                let sx = stringX0 + CGFloat(i) * stringGap
                let lit = Self.labels[i] == closestString && isActive
                let pegIdx = i < 3 ? i : i - 3
                let py = pegYs[pegIdx]
                let px: CGFloat = i < 3
                    ? cx - neckW / 2 - pegDist
                    : cx + neckW / 2 + pegDist

                // Post (peg to string)
                var post = Path()
                post.move(to: CGPoint(x: px, y: py))
                post.addLine(to: CGPoint(x: sx, y: py))
                let postColor = lit
                    ? Color(red: 0, green: 0.82, blue: 0.65, opacity: 0.4)
                    : Color(white: 1, opacity: 0.06)
                ctx.stroke(post, with: .color(postColor), lineWidth: 1)

                // String
                var sp = Path()
                sp.move(to: CGPoint(x: sx, y: py))
                sp.addLine(to: CGPoint(x: sx, y: h))
                let stringColor = lit
                    ? Self.accent
                    : Color(white: 1, opacity: 0.1)
                ctx.stroke(
                    sp,
                    with: .color(stringColor),
                    lineWidth: Self.stringThickness[i] * (lit ? 1.6 : 1)
                )

                // Peg glow
                if lit {
                    let gr = pegR + 6
                    ctx.fill(
                        Circle().path(in: CGRect(x: px - gr, y: py - gr, width: gr * 2, height: gr * 2)),
                        with: .color(Color(red: 0, green: 0.82, blue: 0.65, opacity: 0.12))
                    )
                }

                // Peg
                let pr = CGRect(x: px - pegR, y: py - pegR, width: pegR * 2, height: pegR * 2)
                let pp = Circle().path(in: pr)
                if lit {
                    ctx.fill(pp, with: .color(Color(red: 0, green: 0.82, blue: 0.65, opacity: 0.2)))
                    ctx.stroke(pp, with: .color(Self.accent), lineWidth: 2)
                } else {
                    ctx.fill(pp, with: .color(Color(white: 1, opacity: 0.04)))
                    ctx.stroke(pp, with: .color(Color(white: 1, opacity: 0.1)), lineWidth: 1)
                }
            }
        }
    }
}

// MARK: - Tuner View

struct TunerView: View {
    @StateObject private var tunerState = TunerState()
    @State private var audioEngine: AudioEngine?

    private static let accent = Color(red: 0.0, green: 0.82, blue: 0.65)
    private static let yellow = Color(red: 0.95, green: 0.78, blue: 0.22)
    private static let bg = Color(red: 0.07, green: 0.09, blue: 0.13)

    private let strings: [(label: String, display: String)] = [
        ("E2", "E"), ("A2", "A"), ("D3", "D"),
        ("G3", "G"), ("B3", "B"), ("E4", "E"),
    ]

    private var hasDetection: Bool { tunerState.detectedFrequency != nil }

    private var tuningStatus: String {
        guard hasDetection else { return "" }
        if abs(tunerState.centsOff) <= 3 { return "Perfect" }
        return tunerState.centsOff < 0 ? "Low" : "High"
    }

    private var statusColor: Color {
        guard hasDetection else { return .clear }
        return abs(tunerState.centsOff) <= 5 ? Self.accent : Self.yellow
    }

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Guitar headstock
                GuitarHeadstockView(
                    closestString: tunerState.closestStringName,
                    isActive: hasDetection
                )
                .frame(height: 200)
                .padding(.top, 8)

                Spacer().frame(height: 24)

                // Note name
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(tunerState.detectedNote)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            hasDetection && abs(tunerState.centsOff) <= 5
                                ? Self.accent : .white
                        )

                    if tunerState.detectedOctave > 0 {
                        Text("\(tunerState.detectedOctave)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .baselineOffset(-6)
                    }
                }

                // Tuning status
                Text(tuningStatus)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(statusColor)
                    .frame(height: 24)
                    .padding(.top, 4)

                // Gauge
                TunerGaugeView(centsOff: tunerState.centsOff, isActive: hasDetection)
                    .frame(height: 36)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                // Frequency + cents
                if let freq = tunerState.detectedFrequency {
                    Text(String(format: "%.1f Hz  ·  %+.0f¢", freq, tunerState.centsOff))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.top, 8)
                }

                Spacer()

                // String selector
                HStack(spacing: 10) {
                    ForEach(strings, id: \.label) { item in
                        let lit = tunerState.closestStringName == item.label
                        VStack(spacing: 2) {
                            Text(item.display)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text(item.label)
                                .font(.system(size: 10, design: .rounded))
                        }
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(lit ? Self.accent.opacity(0.12) : .white.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(lit ? Self.accent : .clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(lit ? Self.accent : .gray)
                    }
                }
                .padding(.bottom, 16)

                // Start / Stop
                Button {
                    toggleTuner()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tunerState.isActive ? "stop.fill" : "mic.fill")
                        Text(tunerState.isActive ? "Stop" : "Start Tuning")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(tunerState.isActive ? .white : Self.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(tunerState.isActive ? .red.opacity(0.7) : Self.accent)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Tuner Control

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
    TunerView()
}
