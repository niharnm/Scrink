import SwiftUI

/// Atmospheric backdrop for the "Signal" identity.
///
/// Replaces the old flat near-black fill. A near-black control-panel field is
/// lit by a soft blue→violet signal bloom, dusted with a faint particle haze,
/// and seated with an edge vignette — so screens read as deep and dimensional
/// instead of a flat void. `intensity` (0…1) scales the bloom so "active" or
/// protected screens can glow brighter and the backdrop reflects state.
struct SignalBackground: View {
    var intensity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base: near-black, lifting a touch toward the bottom so the
                // field has subtle vertical depth rather than a single flat tone.
                LinearGradient(
                    colors: [
                        RinklerColors.hex(0x06070A),
                        RinklerColors.hex(0x0A0C12),
                        RinklerColors.hex(0x0E1018),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Primary signal bloom — high right, the cool blue light source.
                RadialGradient(
                    colors: [RinklerColors.signalBlue.opacity(0.30 * intensity), .clear],
                    center: UnitPoint(x: 0.80, y: 0.10),
                    startRadius: 0,
                    endRadius: geo.size.width * 1.0
                )
                .blendMode(.screen)

                // Secondary violet bloom — low left, gives the field depth and a
                // sense of two lights rather than one even wash.
                RadialGradient(
                    colors: [RinklerColors.signalViolet.opacity(0.24 * intensity), .clear],
                    center: UnitPoint(x: 0.10, y: 0.86),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.95
                )
                .blendMode(.screen)

                // Faint particle haze for texture (kills the "flat gradient" look).
                SignalHaze(size: geo.size)
                    .opacity(0.6)
                    .allowsHitTesting(false)

                // Vignette to seat content and darken the corners.
                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.55)],
                    center: .center,
                    startRadius: geo.size.height * 0.28,
                    endRadius: geo.size.height * 0.92
                )
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Particle haze

/// A faint, slow-drifting dust of cool particles rendered in one Canvas.
/// Positions are deterministic (seeded) so the field is stable across redraws.
/// Much dimmer and cooler than the Living Sky starfield — it reads as texture,
/// not as "stars".
private struct SignalHaze: View {
    let size: CGSize
    private let motes: [Mote] = Mote.field(count: 70)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, canvasSize in
                for mote in motes {
                    let drift = CGFloat((t * mote.speed).truncatingRemainder(dividingBy: 1.0))
                    var y = (mote.y - drift * 0.05).truncatingRemainder(dividingBy: 1.0)
                    if y < 0 { y += 1 }
                    let px = mote.x * canvasSize.width
                    let py = y * canvasSize.height
                    let twinkle = 0.5 + 0.5 * sin(t * mote.twinkleSpeed + mote.phase)
                    let alpha = mote.baseAlpha * (0.4 + 0.6 * twinkle)
                    let rect = CGRect(x: px, y: py, width: mote.radius, height: mote.radius)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }
            }
        }
    }
}

private struct Mote {
    let x: Double
    let y: Double
    let radius: CGFloat
    let baseAlpha: Double
    let speed: Double
    let twinkleSpeed: Double
    let phase: Double

    static func field(count: Int) -> [Mote] {
        var seed: UInt64 = 0x2545F4914F6CDD1D
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(UInt64(1) << 53)
        }
        return (0..<count).map { _ in
            let bright = next()
            return Mote(
                x: next(),
                y: next(),
                radius: 0.6 + CGFloat(bright) * 1.1,
                baseAlpha: 0.05 + bright * 0.14,
                speed: 0.4 + next() * 1.0,
                twinkleSpeed: 0.3 + next() * 0.9,
                phase: next() * 6.283
            )
        }
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
        VStack {
            Text("Frosted card")
                .foregroundStyle(.white)
                .padding(40)
                .signalCard(cornerRadius: 22)
        }
    }
}
