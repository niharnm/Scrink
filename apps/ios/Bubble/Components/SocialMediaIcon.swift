import SwiftUI

struct SocialMediaIcon: View {
    let platform: String
    var size: CGFloat = BubbleSpacing.appIconMedium
    
    var body: some View {
        Group {
            switch platform.lowercased() {
            case "instagram":
                InstagramIcon(size: size)
            case "facebook", "shield":
                FacebookIcon(size: size)
            case "kalshi":
                KalshiIcon(size: size)
            case "fanduel":
                FanduelIcon(size: size)
            default:
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(BubbleColors.skyBlue)
            }
        }
    }
}

struct InstagramIcon: View {
    let size: CGFloat
    
    var body: some View {
        SVGView(svgName: "instagram")
            .frame(width: size, height: size)
    }
}

struct FacebookIcon: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Facebook shield icon
            Path { path in
                let center = size / 2
                let radius = size * 0.3
                
                // Shield shape
                path.move(to: CGPoint(x: center, y: size * 0.2))
                path.addLine(to: CGPoint(x: center - radius * 0.8, y: size * 0.3))
                path.addQuadCurve(
                    to: CGPoint(x: center - radius * 0.8, y: size * 0.6),
                    control: CGPoint(x: center - radius * 1.2, y: size * 0.45)
                )
                path.addLine(to: CGPoint(x: center, y: size * 0.75))
                path.addLine(to: CGPoint(x: center + radius * 0.8, y: size * 0.6))
                path.addQuadCurve(
                    to: CGPoint(x: center + radius * 0.8, y: size * 0.3),
                    control: CGPoint(x: center + radius * 1.2, y: size * 0.45)
                )
                path.closeSubpath()
            }
            .fill(BubbleColors.skyBlue)
            
            // Letter F
            Text("F")
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

struct KalshiIcon: View {
    let size: CGFloat

    var body: some View {
        SVGView(svgName: "kalshi")
            .frame(width: size * 0.7, height: size * 0.7)
    }
}

struct FanduelIcon: View {
    let size: CGFloat
    
    var body: some View {
        SVGView(svgName: "fanduel")
            .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        HStack(spacing: 20) {
            SocialMediaIcon(platform: "instagram")
            SocialMediaIcon(platform: "facebook")
            SocialMediaIcon(platform: "kalshi")
            SocialMediaIcon(platform: "fanduel")
        }
    }
}
