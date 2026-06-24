import SwiftUI

/// The opening animation — acts out what Rinkler does, in ~3.2s:
/// 1. a feed doomscrolls upward, accelerating (the trap),
/// 2. a blue line cuts across and the feed dims out (Rinkler interrupts it),
/// 3. the cut resolves INTO the Rinkler logo — the control ring draws on around
///    the cut, then the phone + pause bars settle, then the wordmark.
/// Then it hands off straight into the app — no tap.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var scrollY: CGFloat = 80
    @State private var feedOpacity: Double = 1
    @State private var cutScale: CGFloat = 0
    @State private var cutOpacity: Double = 0
    @State private var ringTrim: CGFloat = 0
    @State private var partsReveal: CGFloat = 0
    @State private var brandText = false

    private let heights: [CGFloat] = [128, 92, 156, 84, 134, 104, 168, 96, 140, 112,
                                      128, 92, 156, 84, 134, 104, 168, 96, 140, 112]

    var body: some View {
        ZStack {
            SignalBackground()

            // 1) The doomscroll.
            feed
                .opacity(feedOpacity)
                .mask(LinearGradient(colors: [.clear, .black, .black, .black, .clear],
                                     startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false)

            // 2) The cut — a blue line that slices across, then becomes the ring.
            Rectangle()
                .fill(RinklerColors.signalBlue)
                .frame(height: 2.5)
                .scaleEffect(x: cutScale, y: 1, anchor: .center)
                .opacity(cutOpacity)
                .padding(.horizontal, 28)

            // 3) The logo resolves out of the cut, then the wordmark.
            VStack(spacing: RinklerSpacing.lg) {
                RinklerLogo(size: 150, ringTrim: ringTrim, partsReveal: partsReveal)

                VStack(spacing: 6) {
                    Text("RINKLER")
                        .font(RinklerFonts.sans(22, .bold))
                        .tracking(6)
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Kill the infinite scroll.")
                        .font(RinklerFonts.sans(12, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                }
                .opacity(brandText ? 1 : 0)
                .offset(y: brandText ? 0 : 10)
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
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
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
        withAnimation(.easeIn(duration: 1.7)) { scrollY = -1700 }

        // Phase 2 — Rinkler cuts in: the line sweeps, the feed goes quiet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeInOut(duration: 0.2)) { cutOpacity = 1 }
            withAnimation(.easeOut(duration: 0.4)) { cutScale = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) { feedOpacity = 0 }
        }

        // Phase 3 — the cut becomes the logo: ring draws on, parts settle, wordmark.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeInOut(duration: 0.5)) { cutOpacity = 0 }
            withAnimation(.easeInOut(duration: 1.0)) { ringTrim = 1 }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.35)) { partsReveal = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { brandText = true }
        }

        // Hand off into the app (~0.4s shorter than before).
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) { onFinished() }
    }
}

#Preview {
    SplashView(onFinished: {})
}
