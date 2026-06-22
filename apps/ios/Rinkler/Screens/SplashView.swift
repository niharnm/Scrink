import SwiftUI

/// The opening animation shown on every cold launch. The signal ring draws itself
/// in around the "pause the scroll" bars, the wordmark rises, then it hands off to
/// the app — no tap required.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var progress: CGFloat = 0
    @State private var appear = false
    @State private var ringSpin = false

    var body: some View {
        ZStack {
            SignalBackground()

            VStack(spacing: RinklerSpacing.lg) {
                SignalRing(progress: progress, lineWidth: 9) {
                    // The "kill the scroll" pause mark at the center of the ring.
                    HStack(spacing: 8) {
                        Capsule().fill(RinklerColors.signalBlue).frame(width: 9, height: 34)
                        Capsule().fill(RinklerColors.signalBlue).frame(width: 9, height: 34)
                    }
                    .opacity(appear ? 1 : 0)
                }
                .frame(width: 152, height: 152)
                .rotationEffect(.degrees(ringSpin ? 0 : -28))
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)

                VStack(spacing: 6) {
                    Text("RINKLER")
                        .font(RinklerFonts.sans(22, .bold))
                        .tracking(6)
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Keep the useful. Kill the scroll.")
                        .font(RinklerFonts.sans(12, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        withAnimation(.easeOut(duration: 0.55)) { appear = true }
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) { ringSpin = true }
        withAnimation(.easeInOut(duration: 1.15).delay(0.15)) { progress = 0.8 }
        // Hand off to the app once the animation has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) { onFinished() }
    }
}

#Preview {
    SplashView(onFinished: {})
}
