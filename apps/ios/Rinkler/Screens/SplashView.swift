import SwiftUI

/// The opening animation — it acts out what Rinkler does, in ~3.6s:
/// 1. a feed doomscrolls upward, accelerating (the trap),
/// 2. a blue line cuts across and the feed dims out (Rinkler interrupts it),
/// 3. the signal ring draws in around the pause-bars mark + wordmark (calm).
/// Then it hands off straight into the app — no tap.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var scrollY: CGFloat = 80
    @State private var feedOpacity: Double = 1
    @State private var cutScale: CGFloat = 0      // 0 → 1 sweeps the cut line across
    @State private var cutOpacity: Double = 0
    @State private var ringProgress: CGFloat = 0
    @State private var ringScale: CGFloat = 0.7
    @State private var brandAppear = false

    // Repeated heights so the stream always has content while it races.
    private let heights: [CGFloat] = [128, 92, 156, 84, 134, 104, 168, 96, 140, 112,
                                      128, 92, 156, 84, 134, 104, 168, 96, 140, 112]

    var body: some View {
        ZStack {
            SignalBackground()

            // 1) The doomscroll.
            feed
                .opacity(feedOpacity)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .black, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)

            // 2) The cut — a blue line that slices across the screen.
            Rectangle()
                .fill(RinklerColors.signalBlue)
                .frame(height: 2.5)
                .scaleEffect(x: cutScale, y: 1, anchor: .center)
                .opacity(cutOpacity)
                .padding(.horizontal, 28)

            // 3) The brand resolves out of the quiet.
            VStack(spacing: RinklerSpacing.lg) {
                SignalRing(progress: ringProgress, lineWidth: 9) {
                    HStack(spacing: 8) {
                        Capsule().fill(RinklerColors.signalBlue).frame(width: 9, height: 32)
                        Capsule().fill(RinklerColors.signalBlue).frame(width: 9, height: 32)
                    }
                    .opacity(brandAppear ? 1 : 0)
                }
                .frame(width: 150, height: 150)
                .scaleEffect(ringScale)
                .opacity(brandAppear ? 1 : 0)

                VStack(spacing: 6) {
                    Text("RINKLER")
                        .font(RinklerFonts.sans(22, .bold))
                        .tracking(6)
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Kill the infinite scroll.")
                        .font(RinklerFonts.sans(12, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                }
                .opacity(brandAppear ? 1 : 0)
                .offset(y: brandAppear ? 0 : 10)
            }
        }
        .onAppear(perform: run)
    }

    private var feed: some View {
        VStack(spacing: 14) {
            ForEach(Array(heights.enumerated()), id: \.offset) { idx, h in
                feedCard(height: h, accent: idx % 4 == 0)
            }
        }
        .offset(y: scrollY)
    }

    private func feedCard(height: CGFloat, accent: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(RinklerColors.signalCard)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(RinklerColors.signalBorder, lineWidth: 1)
            )
            .overlay(
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle().fill(RinklerColors.signalCardRaised).frame(width: 18, height: 18)
                        Capsule().fill(RinklerColors.signalCardRaised).frame(width: 70, height: 6)
                        Spacer()
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle((accent ? RinklerColors.signalBlue : RinklerColors.signalTextFaint).opacity(0.55))
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(14)
            )
            .frame(height: height)
            .padding(.horizontal, 36)
    }

    private func run() {
        // Phase 1 — the feed races upward, accelerating.
        withAnimation(.easeIn(duration: 1.9)) { scrollY = -1700 }

        // Phase 2 — Rinkler cuts in: the line sweeps, the feed goes quiet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            withAnimation(.easeInOut(duration: 0.2)) { cutOpacity = 1 }
            withAnimation(.easeOut(duration: 0.45)) { cutScale = 1 }
            withAnimation(.easeOut(duration: 0.55).delay(0.15)) { feedOpacity = 0 }
        }

        // Phase 3 — the brand resolves out of the quiet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
            withAnimation(.easeInOut(duration: 0.5)) { cutOpacity = 0 }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                ringScale = 1; brandAppear = true
            }
            withAnimation(.easeInOut(duration: 1.1)) { ringProgress = 0.8 }
        }

        // Hand off into the app.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) { onFinished() }
    }
}

#Preview {
    SplashView(onFinished: {})
}
