import SwiftUI

/// Story Mode — Intro.
///
/// A one-time, cinematic onboarding shown on first launch. Each page advances
/// the sky from deep night toward dawn, so the user *watches* the core promise
/// happen: as you move through, the haze lifts. The copy frames the real problem
/// (engineered feeds), Rinkler's distinct approach (remove the feed, keep the
/// app), and the honest mechanism (on-device network filtering, no snooping).
struct StoryIntroView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private struct Panel: Identifiable {
        let id = UUID()
        let kicker: String
        let title: String
        let body: String
        let symbol: String
        let clarity: Double
    }

    private let panels: [Panel] = [
        Panel(
            kicker: "THE PROBLEM",
            title: "Your attention is being farmed.",
            body: "Infinite feeds aren't broken — they're working exactly as designed. Short video is engineered to take your evening one swipe at a time.",
            symbol: "infinity",
            clarity: 0.06
        ),
        Panel(
            kicker: "IT'S NOT WILLPOWER",
            title: "The feed always wins on reflex.",
            body: "Reels and TikTok load the next hit before you decide to stay. No amount of \"just one more\" was ever a fair fight.",
            symbol: "bolt.horizontal.fill",
            clarity: 0.20
        ),
        Panel(
            kicker: "THE RINKLER WAY",
            title: "Keep the app.\nLose the feed.",
            body: "Most blockers lock the whole app, so you cave and turn them off. Rinkler interrupts only the endless short-video stream — your DMs, posts, and search still work.",
            symbol: "scissors",
            clarity: 0.42
        ),
        Panel(
            kicker: "HONEST BY DESIGN",
            title: "It never reads your life.",
            body: "Filtering runs on your device at the network layer. Rinkler sees that a heavy video stream is loading — not your messages, not your photos, not the page you're on.",
            symbol: "lock.shield.fill",
            clarity: 0.62
        ),
        Panel(
            kicker: "STORY MODE",
            title: "Every session clears the sky.",
            body: "Each focus session you protect lifts the haze for good. Build a streak and the night turns to dawn — a world that remembers the time you took back.",
            symbol: "sparkles",
            clarity: 0.86
        ),
    ]

    private var currentClarity: Double {
        panels[min(page, panels.count - 1)].clarity
    }

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: currentClarity)
                .animation(.easeInOut(duration: 0.7), value: page)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(RinklerFonts.coolvetica(size: 15))
                        .foregroundStyle(RinklerColors.white60)
                        .padding(.horizontal, RinklerSpacing.lg)
                        .padding(.top, RinklerSpacing.sm)
                }

                TabView(selection: $page) {
                    ForEach(Array(panels.enumerated()), id: \.element.id) { index, panel in
                        panelView(panel)
                            .tag(index)
                            .padding(.horizontal, RinklerSpacing.xl)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Dots
                HStack(spacing: 8) {
                    ForEach(panels.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? RinklerColors.auroraCyan : RinklerColors.white30)
                            .frame(width: i == page ? 22 : 7, height: 7)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.bottom, RinklerSpacing.lg)

                // CTA
                Group {
                    if page == panels.count - 1 {
                        AuroraButton(title: "BEGIN") { finish() }
                    } else {
                        AuroraButton(title: "NEXT") {
                            withAnimation { page = min(page + 1, panels.count - 1) }
                        }
                    }
                }
                .padding(.horizontal, RinklerSpacing.xl)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func panelView(_ panel: Panel) -> some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
            Spacer()

            Image(systemName: panel.symbol)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(RinklerColors.auroraCyan)
                .shadow(color: RinklerColors.auroraCyan.opacity(0.5), radius: 18)

            VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                Text(panel.kicker)
                    .font(RinklerFonts.caption)
                    .tracking(2)
                    .foregroundStyle(RinklerColors.white40)

                Text(panel.title)
                    .font(RinklerFonts.sans(38, .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(panel.body)
                    .font(RinklerFonts.sans(17, .regular))
                    .foregroundStyle(RinklerColors.white60)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func finish() {
        Story.hasSeenIntro = true
        onFinish()
    }
}

#Preview {
    StoryIntroView(onFinish: {})
        .preferredColorScheme(.dark)
}
