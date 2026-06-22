import SwiftUI

/// Rinkler's block screen — shown when a tracked feed is cut.
///
/// Unique angle (vs every competitor): it CELEBRATES the block instead of
/// punishing or stalling you. A "dead air" signal motif + a live tally of what
/// you just won (pulls dodged, time back, streak), so a block reads as a point
/// scored, not a wall. Competitors lock you out (Opal) or make you breathe
/// (one sec) — both wear off; positive reinforcement doesn't.
///
/// This is also the exact UI the Family Controls *Shield* will render once that
/// entitlement is granted, so it then appears over the blocked app itself.
struct BlockScreen: View {
    var appName: String = "Instagram"
    var surface: String = "Reels"
    var pullsDodged: Int = 0
    var minutesReclaimed: Int = 0
    var streakDays: Int = 0
    /// Quiet escape that routes to the gamified unblock. nil hides it.
    var onLetMeIn: (() -> Void)? = nil
    /// Primary "I'm good" dismiss. nil hides it.
    var onDone: (() -> Void)? = nil

    @State private var fade = false

    var body: some View {
        ZStack {
            SignalBackground()

            VStack(spacing: RinklerSpacing.lg) {
                Spacer()

                Text("DEAD AIR")
                    .font(RinklerFonts.mono(13, .medium))
                    .tracking(5)
                    .foregroundStyle(RinklerColors.signalTextFaint)

                // The signal that just went quiet — a flatline with one last blip.
                Flatline()
                    .stroke(RinklerColors.signalBlue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(height: 70)
                    .padding(.horizontal, RinklerSpacing.xl)
                    .opacity(fade ? 0.45 : 1)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: fade)

                VStack(spacing: 10) {
                    Text("\(surface) is quiet now.")
                        .font(RinklerFonts.sans(30, .bold))
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Rinkler cut the \(appName) feed. DMs and search still work — there's just nothing left here to suck you in.")
                        .font(RinklerFonts.sans(15, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, RinklerSpacing.lg)
                }

                // The win — blocking is a score, not a punishment.
                RinklerStatRow(stats: [
                    ("Pulls dodged", "\(pullsDodged)", RinklerColors.signalBlue),
                    ("Time back", timeLabel, nil),
                    ("Streak", "\(streakDays)d", nil),
                ])
                .padding(.vertical, RinklerSpacing.md)
                .frame(maxWidth: .infinity)
                .signalCard(cornerRadius: 18)
                .padding(.horizontal, RinklerSpacing.lg)

                Spacer()

                if let onDone {
                    Button(action: onDone) {
                        Text("Good. I'm out")
                            .font(RinklerFonts.sans(17, .semibold))
                            .foregroundStyle(RinklerColors.signalOnInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(RinklerColors.signalInk)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, RinklerSpacing.lg)
                }

                if let onLetMeIn {
                    Button(action: onLetMeIn) {
                        Text("Let me in anyway")
                            .font(RinklerFonts.sans(14, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, RinklerSpacing.xl)
        }
        .onAppear { fade = true }
    }

    private var timeLabel: String {
        if minutesReclaimed >= 60 {
            let h = minutesReclaimed / 60, m = minutesReclaimed % 60
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
        return "\(minutesReclaimed)m"
    }

}

/// A heart-monitor-style line that beats once, then goes flat — "signal's gone."
private struct Flatline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midY = rect.midY
        p.move(to: CGPoint(x: rect.minX, y: midY))
        // a couple of fading beats on the left third
        let beat = rect.width * 0.06
        var x = rect.minX + rect.width * 0.06
        p.addLine(to: CGPoint(x: x, y: midY))
        p.addLine(to: CGPoint(x: x + beat * 0.4, y: rect.minY + rect.height * 0.18))
        p.addLine(to: CGPoint(x: x + beat * 0.8, y: rect.maxY - rect.height * 0.1))
        p.addLine(to: CGPoint(x: x + beat * 1.2, y: midY))
        x += beat * 1.2
        // then flat to the right edge
        p.addLine(to: CGPoint(x: rect.maxX, y: midY))
        return p
    }
}

#Preview {
    BlockScreen(appName: "Instagram", surface: "Reels", pullsDodged: 47,
                minutesReclaimed: 72, streakDays: 5, onLetMeIn: {}, onDone: {})
}
