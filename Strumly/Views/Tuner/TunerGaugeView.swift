import SwiftUI

/// A horizontal sliding-needle gauge that shows tuning accuracy.
/// The needle slides left (flat) or right (sharp) from center, changing
/// color from green (in tune) to yellow (off tune).
struct TunerGaugeView: View {
    let centsOff: Double
    let isActive: Bool

    private let inTuneColor = Color(red: 0.0, green: 0.82, blue: 0.65)
    private let offTuneColor = Color(red: 0.95, green: 0.78, blue: 0.22)

    private var needleColor: Color {
        guard isActive else { return .gray }
        return abs(centsOff) <= 5 ? inTuneColor : offTuneColor
    }

    private var normalizedOffset: CGFloat {
        guard isActive else { return 0 }
        return min(max(centsOff, -50), 50) / 50.0
    }

    var body: some View {
        GeometryReader { geo in
            let midX = geo.size.width / 2
            let midY = geo.size.height / 2
            let needleX = midX + normalizedOffset * midX * 0.85

            // Track
            Capsule()
                .fill(.white.opacity(0.06))
                .frame(height: 3)
                .position(x: midX, y: midY)

            // Center dot
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 6, height: 6)
                .position(x: midX, y: midY)

            // Sliding needle
            RoundedRectangle(cornerRadius: 2)
                .fill(needleColor)
                .frame(width: 4, height: geo.size.height * 0.7)
                .shadow(color: needleColor.opacity(0.5), radius: 6)
                .position(x: needleX, y: midY)
                .animation(.spring(response: 0.12, dampingFraction: 0.7), value: centsOff)
        }
    }
}

#Preview("In Tune") {
    TunerGaugeView(centsOff: 0, isActive: true)
        .frame(height: 40).padding()
        .background(Color(red: 0.07, green: 0.09, blue: 0.13))
}

#Preview("Low") {
    TunerGaugeView(centsOff: -25, isActive: true)
        .frame(height: 40).padding()
        .background(Color(red: 0.07, green: 0.09, blue: 0.13))
}

#Preview("High") {
    TunerGaugeView(centsOff: 30, isActive: true)
        .frame(height: 40).padding()
        .background(Color(red: 0.07, green: 0.09, blue: 0.13))
}
