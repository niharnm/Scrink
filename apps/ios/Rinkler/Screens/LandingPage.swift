import SwiftUI

struct LandingPage: View {
    var onGo: () -> Void

    var body: some View {
        ZStack {
            SignalBackground()

            // Signature hero: a luminous signal ring rising in the upper field,
            // partly off-screen so it reads as a large, present object rather
            // than a small decoration.
            SignalRing(progress: 0.72, lineWidth: 10)
                .frame(width: 340, height: 340)
                .opacity(0.9)
                .offset(x: 120, y: -230)

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
                    .foregroundStyle(RinklerColors.signalOnInk)
                    .padding(.horizontal, RinklerSpacing.lg)
                    .frame(height: 58)
                    .frame(maxWidth: .infinity)
                    .background(RinklerColors.signalInk)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, RinklerSpacing.lg)
            .padding(.bottom, RinklerSpacing.xl)
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(nil)
        .onAppear {
            SVGCache.shared.preload(svgNames: ["instagram"])
        }
    }
}

#Preview {
    LandingPage(onGo: {})
}
