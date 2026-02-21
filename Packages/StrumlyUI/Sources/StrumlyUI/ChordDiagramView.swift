import SwiftUI
import StrumlyCore

// MARK: - ChordDiagramView

/// A SwiftUI view that renders a guitar chord fingering diagram using `Canvas`.
///
/// The diagram shows:
/// - A fretboard grid with 6 vertical string lines and horizontal fret lines
/// - A thick nut line at top when `baseFret == 1` (open position)
/// - Filled finger dots at correct string/fret positions with finger numbers (1-4) inside
/// - "O" above the nut for open strings (`fret == 0`)
/// - "X" above the nut for muted strings (`fret == -1`)
/// - Rounded rectangle barre indicators spanning multiple strings
/// - A base fret label ("Nfr") to the left when `baseFret > 1`
public struct ChordDiagramView: View {

    // MARK: - Properties

    let voicing: Voicing
    let chordName: String
    let fretCount: Int

    // MARK: - Layout Constants

    private let topPadding: CGFloat = 30
    private let bottomPadding: CGFloat = 10
    private let sidePadding: CGFloat = 30
    private let dotRadius: CGFloat = 10
    private let nutThickness: CGFloat = 4
    private let fretLineWidth: CGFloat = 1
    private let stringLineWidth: CGFloat = 1

    // MARK: - Initializer

    public init(voicing: Voicing, chordName: String, fretCount: Int = 4) {
        self.voicing = voicing
        self.chordName = chordName
        self.fretCount = fretCount
    }

    // MARK: - Body

    public var body: some View {
        Canvas { context, size in
            let stringSpacing = (size.width - 2 * sidePadding) / 5
            let fretSpacing = (size.height - topPadding - bottomPadding) / CGFloat(fretCount)

            drawFretboard(context: &context, size: size, stringSpacing: stringSpacing, fretSpacing: fretSpacing)
            drawNutOrBaseFretLabel(context: &context, size: size, stringSpacing: stringSpacing, fretSpacing: fretSpacing)
            drawBarres(context: &context, stringSpacing: stringSpacing, fretSpacing: fretSpacing)
            drawFingerDots(context: &context, stringSpacing: stringSpacing, fretSpacing: fretSpacing)
            drawOpenAndMutedMarkers(context: &context, stringSpacing: stringSpacing)
        }
        .frame(width: 160, height: 200)
    }

    // MARK: - Drawing: Fretboard Grid

    /// Draws the 6 vertical string lines and horizontal fret lines.
    private func drawFretboard(
        context: inout GraphicsContext,
        size: CGSize,
        stringSpacing: CGFloat,
        fretSpacing: CGFloat
    ) {
        let gridColor = Color.primary.opacity(0.6)

        // Draw horizontal fret lines
        for fretIndex in 0...fretCount {
            let y = topPadding + CGFloat(fretIndex) * fretSpacing
            var path = Path()
            path.move(to: CGPoint(x: sidePadding, y: y))
            path.addLine(to: CGPoint(x: sidePadding + 5 * stringSpacing, y: y))
            context.stroke(path, with: .color(gridColor), lineWidth: fretLineWidth)
        }

        // Draw vertical string lines
        for stringIndex in 0..<6 {
            let x = sidePadding + CGFloat(stringIndex) * stringSpacing
            var path = Path()
            path.move(to: CGPoint(x: x, y: topPadding))
            path.addLine(to: CGPoint(x: x, y: topPadding + CGFloat(fretCount) * fretSpacing))
            context.stroke(path, with: .color(gridColor), lineWidth: stringLineWidth)
        }
    }

    // MARK: - Drawing: Nut / Base Fret Label

    /// Draws a thick nut line at the top when `baseFret == 1`, or a base fret label when `baseFret > 1`.
    private func drawNutOrBaseFretLabel(
        context: inout GraphicsContext,
        size: CGSize,
        stringSpacing: CGFloat,
        fretSpacing: CGFloat
    ) {
        if voicing.baseFret == 1 {
            // Draw thick nut line
            var nutPath = Path()
            nutPath.move(to: CGPoint(x: sidePadding, y: topPadding))
            nutPath.addLine(to: CGPoint(x: sidePadding + 5 * stringSpacing, y: topPadding))
            context.stroke(nutPath, with: .color(.primary), lineWidth: nutThickness)
        } else {
            // Draw base fret label to the left
            let label = "\(voicing.baseFret)fr"
            let text = Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
            let resolved = context.resolve(text)
            let textSize = resolved.measure(in: CGSize(width: 100, height: 100))
            let x: CGFloat = sidePadding - textSize.width - 4
            let y = topPadding + fretSpacing * 0.5 - textSize.height / 2
            context.draw(resolved, at: CGPoint(x: x + textSize.width / 2, y: y + textSize.height / 2))
        }
    }

    // MARK: - Drawing: Barre Indicators

    /// Draws rounded rectangle barre indicators spanning multiple strings at the barre fret.
    private func drawBarres(
        context: inout GraphicsContext,
        stringSpacing: CGFloat,
        fretSpacing: CGFloat
    ) {
        guard let barres = voicing.barres else { return }

        for barre in barres {
            let fromX = sidePadding + CGFloat(barre.fromString - 1) * stringSpacing
            let toX = sidePadding + CGFloat(barre.toString - 1) * stringSpacing
            let y = topPadding + (CGFloat(barre.fret) - 0.5) * fretSpacing
            let barreHeight = dotRadius * 1.6
            let minX = min(fromX, toX)
            let maxX = max(fromX, toX)

            let barreRect = CGRect(
                x: minX - dotRadius * 0.3,
                y: y - barreHeight / 2,
                width: maxX - minX + dotRadius * 0.6,
                height: barreHeight
            )
            let barrePath = Path(roundedRect: barreRect, cornerRadius: barreHeight / 2)
            context.fill(barrePath, with: .color(.primary))
        }
    }

    // MARK: - Drawing: Finger Dots

    /// Draws filled circles at correct string/fret positions with finger numbers (1-4) inside.
    private func drawFingerDots(
        context: inout GraphicsContext,
        stringSpacing: CGFloat,
        fretSpacing: CGFloat
    ) {
        for (stringIndex, stringFret) in voicing.strings.enumerated() {
            guard stringFret.fret > 0 else { continue }

            // Skip drawing individual dots for strings that are part of a barre,
            // unless they have a distinct finger number.
            if let barres = voicing.barres {
                let isPartOfBarre = barres.contains { barre in
                    barre.fret == stringFret.fret
                    && stringIndex + 1 >= min(barre.fromString, barre.toString)
                    && stringIndex + 1 <= max(barre.fromString, barre.toString)
                    && stringFret.finger == nil
                }
                if isPartOfBarre { continue }
            }

            let x = sidePadding + CGFloat(stringIndex) * stringSpacing
            let y = topPadding + (CGFloat(stringFret.fret) - 0.5) * fretSpacing

            // Draw filled circle
            let dotRect = CGRect(
                x: x - dotRadius,
                y: y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            let dotPath = Path(ellipseIn: dotRect)
            context.fill(dotPath, with: .color(.primary))

            // Draw finger number inside the dot
            if let finger = stringFret.finger {
                let fingerText = Text("\(finger)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                let resolved = context.resolve(fingerText)
                context.draw(resolved, at: CGPoint(x: x, y: y))
            }
        }
    }

    // MARK: - Drawing: Open & Muted String Markers

    /// Draws "O" above the nut for open strings and "X" for muted strings.
    private func drawOpenAndMutedMarkers(
        context: inout GraphicsContext,
        stringSpacing: CGFloat
    ) {
        let markerY = topPadding - 14

        for (stringIndex, stringFret) in voicing.strings.enumerated() {
            let x = sidePadding + CGFloat(stringIndex) * stringSpacing

            if stringFret.fret == 0 {
                // Open string: draw "O"
                let text = Text("O")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                let resolved = context.resolve(text)
                context.draw(resolved, at: CGPoint(x: x, y: markerY))
            } else if stringFret.fret == -1 {
                // Muted string: draw "X"
                let text = Text("X")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                let resolved = context.resolve(text)
                context.draw(resolved, at: CGPoint(x: x, y: markerY))
            }
        }
    }
}

// MARK: - Preview

#Preview("Am Chord") {
    ChordDiagramView(
        voicing: Voicing(
            strings: [
                StringFret(fret: -1),               // Low E: muted
                StringFret(fret: 0),                 // A: open
                StringFret(fret: 2, finger: 2),      // D: 2nd fret, middle finger
                StringFret(fret: 2, finger: 3),      // G: 2nd fret, ring finger
                StringFret(fret: 1, finger: 1),      // B: 1st fret, index finger
                StringFret(fret: 0)                  // High E: open
            ],
            baseFret: 1
        ),
        chordName: "Am"
    )
    .padding()
}
