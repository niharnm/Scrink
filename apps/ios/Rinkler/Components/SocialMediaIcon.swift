import SwiftUI

struct SocialMediaIcon: View {
    let platform: String
    var size: CGFloat = RinklerSpacing.appIconMedium
    
    var body: some View {
        Group {
            switch platform.lowercased() {
            case "instagram":
                InstagramIcon(size: size)
            case "tiktok":
                TikTokIcon(size: size)
            case "youtube":
                YouTubeIcon(size: size)
            case "facebook", "shield":
                FacebookIcon(size: size)
            default:
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(RinklerColors.skyBlue)
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

struct TikTokIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct YouTubeIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(Color.red)
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
        }
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
            .fill(RinklerColors.skyBlue)
            
            // Letter F
            Text("F")
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ZStack {
        RinklerColors.skyGradient.ignoresSafeArea()
        HStack(spacing: 20) {
            SocialMediaIcon(platform: "instagram")
            SocialMediaIcon(platform: "tiktok")
            SocialMediaIcon(platform: "youtube")
            SocialMediaIcon(platform: "facebook")
        }
    }
}
