import SwiftUI

/// Atmospheric backdrop for the "Signal" identity.
///
/// A near-black control-panel field lit by a soft blue→violet signal bloom and
/// seated with an edge vignette, so screens read as deep and dimensional instead
/// of a flat void. `intensity` (0…1) scales the bloom so "active" screens can
/// glow brighter.
///
/// Deliberately static: no `Canvas`, `TimelineView`, or `.blendMode`. Those were
/// causing a black screen on the iOS 26/27 betas (the render server choked on the
/// continuously-animating Canvas behind the whole view tree). Plain gradients
/// composite reliably everywhere.
struct SignalBackground: View {
    var intensity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base: near-black, lifting a touch toward the bottom.
                LinearGradient(
                    colors: [
                        RinklerColors.hex(0x06070A),
                        RinklerColors.hex(0x0A0C12),
                        RinklerColors.hex(0x121520),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Primary signal bloom — high right, cool blue light source.
                RadialGradient(
                    colors: [RinklerColors.signalBlue.opacity(0.26 * intensity), .clear],
                    center: UnitPoint(x: 0.82, y: 0.08),
                    startRadius: 0,
                    endRadius: geo.size.width * 1.05
                )

                // Secondary violet bloom — low left, for depth.
                RadialGradient(
                    colors: [RinklerColors.signalViolet.opacity(0.22 * intensity), .clear],
                    center: UnitPoint(x: 0.08, y: 0.9),
                    startRadius: 0,
                    endRadius: geo.size.width * 1.0
                )

                // Vignette to seat content and darken the corners.
                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.5)],
                    center: .center,
                    startRadius: geo.size.height * 0.3,
                    endRadius: geo.size.height * 0.95
                )
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Frosted card

extension View {
    /// Frosted "signal glass": a translucent blurred surface with a top-lit
    /// hairline and a soft drop shadow, so cards read as raised glass over the
    /// atmospheric background instead of flat fills (the Opal "pill" standard).
    func signalCard(cornerRadius: CGFloat = 18) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(shape.fill(Color.white.opacity(0.05)))
            .background(.ultraThinMaterial, in: shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .clipShape(shape)
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        SignalBackground()
        Text("Signal").foregroundStyle(.white).padding(40).signalCard(cornerRadius: 22)
    }
}
