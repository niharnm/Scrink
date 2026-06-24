import SwiftUI

/// Shown right before iOS's Screen Time (Family Controls) system prompt so the
/// user knows WHY Rinkler asks — priming like this measurably cuts the drop-off
/// the unexplained system dialog causes. Tapping Continue triggers the real
/// Apple prompt via `onContinue`.
struct ScreenTimePrimingView: View {
    var onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SignalBackground()
            VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                Spacer(minLength: 0)

                Image(systemName: "hourglass")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(RinklerColors.signalBlue)
                Text("Next: allow Screen Time")
                    .font(RinklerFonts.sans(24, .bold))
                    .foregroundStyle(RinklerColors.signalText)
                Text("Apple will pop up asking to let Rinkler use Screen Time. Tap Allow — that's what lets Rinkler do the hard stuff.")
                    .font(RinklerFonts.sans(15, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                    primingRow("lock.shield.fill", "Hard-block any app you pick — the block that actually holds.")
                    primingRow("chart.bar.fill", "Show your real per-app screen time.")
                    primingRow("hand.raised.fill", "Apple keeps it on your device. Rinkler never sees your other apps.")
                }
                .padding(.top, RinklerSpacing.sm)

                Spacer(minLength: 0)

                Button { dismiss(); onContinue() } label: {
                    Text("Continue")
                        .font(RinklerFonts.sans(16, .semibold))
                        .foregroundStyle(RinklerColors.signalOnInk)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(RinklerColors.signalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { dismiss() } label: {
                    Text("Not now")
                        .font(RinklerFonts.sans(14, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .frame(maxWidth: .infinity).frame(height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(RinklerSpacing.lg)
        }
    }

    private func primingRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: RinklerSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RinklerColors.signalBlue)
                .frame(width: 24)
            Text(text)
                .font(RinklerFonts.sans(14, .regular))
                .foregroundStyle(RinklerColors.signalText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
