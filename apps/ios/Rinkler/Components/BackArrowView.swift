import SwiftUI

struct BackArrowView: View {
    var size: CGFloat = 34
    var color: Color = Color(red: 0.047, green: 0.424, blue: 0.761) // #0C6CC2
    
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 34, geometry.size.height / 22)
            let offsetX = (geometry.size.width - 34 * scale) / 2
            let offsetY = (geometry.size.height - 22 * scale) / 2
            
            Path { path in
                // Transform function to convert SVG coordinates to SwiftUI coordinates
                func t(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                    CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)
                }
                
                // SVG path: M12.2628 0.45054L0.74007 9.79681C-0.276202 10.6211 -0.240184 12.1832 0.813002 12.9598L12.3358 21.4564C13.6562 22.4301 15.5227 21.4873 15.5227 19.8467V18.7905C15.5227 17.686 16.4181 16.7905 17.5227 16.7905H31.7322C32.8367 16.7905 33.7322 15.8951 33.7322 14.7905V8.26671C33.7322 7.16214 32.8367 6.26671 31.7322 6.26671H17.5227C16.4181 6.26671 15.5227 5.37128 15.5227 4.26671V2.00382C15.5227 0.320529 13.5701 -0.609839 12.2628 0.45054Z
                
                path.move(to: t(12.2628, 0.45054))
                path.addLine(to: t(0.74007, 9.79681))
                path.addCurve(to: t(0.813002, 12.9598), control1: t(-0.276202, 10.6211), control2: t(-0.240184, 12.1832))
                path.addLine(to: t(12.3358, 21.4564))
                path.addCurve(to: t(15.5227, 19.8467), control1: t(13.6562, 22.4301), control2: t(15.5227, 21.4873))
                path.addLine(to: t(15.5227, 18.7905))
                path.addCurve(to: t(17.5227, 16.7905), control1: t(15.5227, 17.686), control2: t(16.4181, 16.7905))
                path.addLine(to: t(31.7322, 16.7905))
                path.addCurve(to: t(33.7322, 14.7905), control1: t(32.8367, 16.7905), control2: t(33.7322, 15.8951))
                path.addLine(to: t(33.7322, 8.26671))
                path.addCurve(to: t(31.7322, 6.26671), control1: t(33.7322, 7.16214), control2: t(32.8367, 6.26671))
                path.addLine(to: t(17.5227, 6.26671))
                path.addCurve(to: t(15.5227, 4.26671), control1: t(16.4181, 6.26671), control2: t(15.5227, 5.37128))
                path.addLine(to: t(15.5227, 2.00382))
                path.addCurve(to: t(12.2628, 0.45054), control1: t(15.5227, 0.320529), control2: t(13.5701, -0.609839))
                path.closeSubpath()
            }
            .fill(color)
        }
        .frame(width: size, height: size * (22.0 / 34.0))
    }
}

#Preview {
    ZStack {
        Color.blue
        BackArrowView(size: 44, color: .white)
    }
}
