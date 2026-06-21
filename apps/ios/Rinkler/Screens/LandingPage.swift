import SwiftUI

struct LandingPage: View {
    var onGo: () -> Void

    var body: some View {
        ZStack {
            SkyBackgroundView()

            VStack(spacing: 0) {
                // Spacer to position text closer to top
                Spacer()
                    .frame(height: UIScreen.main.bounds.height / 6)

                // Title block - positioned closer to top, slightly to the right
                VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
                    Text("RINKLER")
                        .font(RinklerFonts.titleLarge)
                        .foregroundStyle(.white)
                    
                    Text("keep the useful parts.")
                        .font(RinklerFonts.subtitleItalic)
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }
                .padding(.leading, RinklerSpacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            
            // Forward arrow button in bottom right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        onGo()
                    } label: {
                        BackArrowView(size: 34, color: .white)
                            .rotationEffect(.degrees(180))
                            .frame(width: 44, height: 44)
                            .background(RinklerColors.skyBlue)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, RinklerSpacing.xl + 10)
                    .padding(.bottom, 14)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            SVGCache.shared.preload(svgNames: ["instagram"])
        }
    }
}

#Preview {
    LandingPage(onGo: {})
}
