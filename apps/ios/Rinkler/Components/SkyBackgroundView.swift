import SwiftUI

/// Rinkler's signature backdrop: a deep night sky that *clears toward dawn* as
/// the user's focus grows.
///
/// `clarity` (0...1) drives the whole mood. At 0 it's flat midnight with a full
/// starfield; as it rises, a warm dawn glow lifts from the horizon and the
/// stars quietly fade. Pass a higher clarity when protection is on or a streak
/// is building so the background literally reflects the user's state. The
/// parameter defaults to a calm resting value so every existing screen that
/// uses `SkyBackgroundView()` keeps working unchanged.
struct SkyBackgroundView: View {
    var clarity: Double = 0.32

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base sky — warms with clarity.
                RinklerColors.livingGradient(clarity: clarity)

                // Dawn glow rising from the horizon. Grows with clarity.
                RadialGradient(
                    colors: [
                        RinklerColors.dawnGlow.opacity(0.34 * clarity),
                        RinklerColors.dawnGlow.opacity(0.0)
                    ],
                    center: UnitPoint(x: 0.5, y: 1.08),
                    startRadius: 0,
                    endRadius: geo.size.height * 0.9
                )

                // Drifting, twinkling starfield. Fades as dawn breaks.
                StarfieldView(size: geo.size)
                    .opacity(0.85 * (1.0 - clarity * 0.8))
                    .allowsHitTesting(false)

                // Subtle top vignette to seat content.
                LinearGradient(
                    colors: [RinklerColors.nightTop.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Starfield

/// A slow-drifting field of stars rendered in a single Canvas. Positions are
/// deterministic (seeded) so the sky is stable across redraws; a capped-rate
/// TimelineView animates a gentle drift and twinkle without a manual Timer.
private struct StarfieldView: View {
    let size: CGSize

    private let stars: [Star] = Star.field(count: 110)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, canvasSize in
                for star in stars {
                    // Gentle upward-left drift, wrapping seamlessly.
                    let drift = CGFloat((t * star.speed).truncatingRemainder(dividingBy: 1.0))
                    var x = (star.x - drift * 0.04).truncatingRemainder(dividingBy: 1.0)
                    if x < 0 { x += 1 }
                    let px = x * canvasSize.width
                    let py = star.y * canvasSize.height

                    // Twinkle: a slow sine on each star's own phase.
                    let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * star.twinkleSpeed + star.phase))
                    let alpha = star.baseAlpha * twinkle

                    let rect = CGRect(x: px, y: py, width: star.radius, height: star.radius)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(alpha))
                    )
                }
            }
        }
    }
}

private struct Star {
    let x: Double          // 0...1 of width
    let y: Double          // 0...1 of height
    let radius: CGFloat
    let baseAlpha: Double
    let speed: Double
    let twinkleSpeed: Double
    let phase: Double

    /// Deterministic starfield from a simple seeded LCG so the sky never
    /// "jumps" between frames or screens.
    static func field(count: Int) -> [Star] {
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(UInt64(1) << 53)
        }
        return (0..<count).map { _ in
            let bright = next()
            return Star(
                x: next(),
                y: next() * 0.92,
                radius: 0.8 + CGFloat(bright) * 1.8,
                baseAlpha: 0.25 + bright * 0.55,
                speed: 0.6 + next() * 1.4,
                twinkleSpeed: 0.4 + next() * 1.2,
                phase: next() * 6.283
            )
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        SkyBackgroundView(clarity: 0.1)
        SkyBackgroundView(clarity: 0.9)
    }
}
