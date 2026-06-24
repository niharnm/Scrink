import SwiftUI

/// App backdrop — "stark minimal", matching the marketing site: a flat true-black
/// canvas. No gradients, blooms, vignette, or animated canvas (those read as
/// generic/slop and broke on the iOS beta). Just black; the type carries the design.
struct SignalBackground: View {
    /// Kept for source compatibility; ignored in the stark theme.
    var intensity: Double = 1.0

    var body: some View {
        RinklerColors.signalBackground
            .ignoresSafeArea(.all)
    }
}

// MARK: - Card

extension View {
    /// A flat card: subtle fill + a single hairline border, no blur/shadow/glow —
    /// matching the site's hairline-separated surfaces.
    func signalCard(cornerRadius: CGFloat = 16) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(RinklerColors.signalCard)
            .overlay(shape.strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(shape)
    }
}

#Preview {
    ZStack {
        SignalBackground()
        Text("Signal").foregroundStyle(.white).padding(40).signalCard()
    }
}
