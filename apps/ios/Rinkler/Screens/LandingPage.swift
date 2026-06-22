import SwiftUI

struct LandingPage: View {
    var onGo: () -> Void

    var body: some View {
        ZStack {
            RinklerColors.signalBackground.ignoresSafeArea()

            // Decorative signal ring glow in the upper field.
            SignalRing(progress: 0.72, lineWidth: 6)
                .frame(width: 260, height: 260)
                .opacity(0.35)
                .blur(radius: 0.5)
                .offset(x: 90, y: -260)

            VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                Spacer()

                Text("RINKLER")
                    .font(RinklerFonts.sans(15, .semibold))
                    .tracking(4)
                    .foregroundStyle(RinklerColors.signalTextDim)

                VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
                    Text("Keep the useful parts.")
                        .font(RinklerFonts.sans(40, .bold))
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Kill the infinite scroll.")
                        .font(RinklerFonts.sans(40, .bold))
                        .foregroundStyle(RinklerColors.signalBlue)
                }
                .fixedSize(horizontal: false, vertical: true)

                Text("Keep Instagram DMs. Kill Reels. Keep YouTube Search. Kill Shorts. Keep your phone — remove the trap.")
                    .font(RinklerFonts.sans(15, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, RinklerSpacing.lg)

                Spacer()

                Button(action: onGo) {
                    HStack {
                        Text("Build your focus system")
                            .font(RinklerFonts.sans(18, .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, RinklerSpacing.lg)
                    .frame(height: 58)
                    .frame(maxWidth: .infinity)
                    .background(RinklerColors.signalGlow)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, RinklerSpacing.lg)
            .padding(.bottom, RinklerSpacing.xl)
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            SVGCache.shared.preload(svgNames: ["instagram"])
        }
    }
}

#Preview {
    LandingPage(onGo: {})
}
