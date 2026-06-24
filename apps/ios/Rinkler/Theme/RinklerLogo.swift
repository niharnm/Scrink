import SwiftUI

/// The Rinkler mark, drawn in SwiftUI from the icon geometry (scripts/
/// generate_logo.swift): a broken "control ring" (gaps left & right) around a
/// phone/hourglass silhouette flanked by pause bars. Vector + animatable so the
/// splash can draw it on, rather than slapping down a static image.
struct RinklerLogo: View {
    var size: CGFloat = 150
    /// 0→1 draws the ring on.
    var ringTrim: CGFloat = 1
    /// 0→1 fades/scales the phone + bars in.
    var partsReveal: CGFloat = 1
    var ringColor: Color = RinklerColors.signalText
    var phoneColor: Color = RinklerColors.signalText
    var barColor: Color = RinklerColors.signalBlue

    var body: some View {
        ZStack {
            RingShape()
                .trim(from: 0, to: max(0.001, ringTrim))
                .stroke(ringColor, style: StrokeStyle(lineWidth: size * 40 / 512, lineCap: .round, lineJoin: .round))

            PhoneShape()
                .fill(phoneColor, style: FillStyle(eoFill: true))
                .opacity(Double(partsReveal))
                .scaleEffect(0.82 + 0.18 * partsReveal)

            BarsShape()
                .fill(barColor)
                .opacity(Double(partsReveal))
                .scaleEffect(0.82 + 0.18 * partsReveal)
        }
        .frame(width: size, height: size)
    }
}

// All shapes work in the icon's 512×512 reference space, scaled to the view.

private struct RingShape: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 512
        let c = CGPoint(x: r.midX, y: r.midY)
        let rad = 150 * s
        func pt(_ deg: CGFloat) -> CGPoint {
            CGPoint(x: c.x + rad * cos(deg * .pi / 180), y: c.y + rad * sin(deg * .pi / 180))
        }
        var p = Path()
        // Two arcs over top & bottom; gaps centered left (180°) and right (0°).
        p.addArc(center: c, radius: rad, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
        p.move(to: pt(200))
        p.addArc(center: c, radius: rad, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        return p
    }
}

private struct PhoneShape: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 512
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * s, y: r.minY + y * s) }
        var p = Path()
        p.move(to: P(204, 168))
        p.addQuadCurve(to: P(222, 150), control: P(204, 150))
        p.addLine(to: P(290, 150))
        p.addQuadCurve(to: P(308, 168), control: P(308, 150))
        p.addCurve(to: P(282, 256), control1: P(308, 212), control2: P(282, 230))
        p.addCurve(to: P(308, 344), control1: P(282, 282), control2: P(308, 300))
        p.addQuadCurve(to: P(290, 362), control: P(308, 362))
        p.addLine(to: P(222, 362))
        p.addQuadCurve(to: P(204, 344), control: P(204, 362))
        p.addCurve(to: P(230, 256), control1: P(204, 300), control2: P(230, 282))
        p.addCurve(to: P(204, 168), control1: P(230, 230), control2: P(204, 212))
        p.closeSubpath()
        // speaker notch (cut via even-odd)
        p.addRoundedRect(in: CGRect(x: r.minX + 241 * s, y: r.minY + 166 * s, width: 30 * s, height: 9 * s),
                         cornerSize: CGSize(width: 4.5 * s, height: 4.5 * s))
        return p
    }
}

private struct BarsShape: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 512
        var p = Path()
        for x in [150.0, 170, 328, 348] as [CGFloat] {
            p.addRoundedRect(in: CGRect(x: r.minX + x * s, y: r.minY + 224 * s, width: 14 * s, height: 64 * s),
                             cornerSize: CGSize(width: 7 * s, height: 7 * s))
        }
        return p
    }
}

#Preview {
    ZStack { SignalBackground(); RinklerLogo(size: 200) }
}
