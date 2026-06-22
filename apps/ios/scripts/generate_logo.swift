import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

// MARK: - Colors (Signal blue -> violet theme)
func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: a)
}
let bgTop = rgb(124, 140, 255)   // periwinkle
let bgBot = rgb(109, 40, 217)    // deep violet
let markBlue = rgb(91, 124, 255) // #5B7CFF
let markViolet = rgb(139, 92, 246) // #8B5CF6
let barCyan = rgb(123, 226, 207) // soft mint accent (nod to original teal bars)
let white = rgb(255, 255, 255)

let cs = CGColorSpace(name: CGColorSpace.sRGB)!

// MARK: - Geometry (512 reference, top-left origin, y-down)
let REF: CGFloat = 512
let C = CGPoint(x: 256, y: 256)

func ringOutline() -> CGPath {
    let R: CGFloat = 150, LW: CGFloat = 40
    let p = CGMutablePath()
    func deg(_ d: CGFloat) -> CGFloat { d * .pi / 180 }
    // gaps centered at 0deg (right) and 180deg (left); two arcs over top & bottom
    p.addArc(center: C, radius: R, startAngle: deg(24), endAngle: deg(156), clockwise: false)
    p.move(to: CGPoint(x: C.x + R*cos(deg(204)), y: C.y + R*sin(deg(204))))
    p.addArc(center: C, radius: R, startAngle: deg(204), endAngle: deg(336), clockwise: false)
    return p.copy(strokingWithWidth: LW, lineCap: .round, lineJoin: .round, miterLimit: 10)
}

// Phone + hourglass silhouette (wide top, pinched middle, wide bottom) with a
// speaker notch cut out (even-odd).
func phonePath() -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: 204, y: 168))
    p.addQuadCurve(to: CGPoint(x: 222, y: 150), control: CGPoint(x: 204, y: 150))
    p.addLine(to: CGPoint(x: 290, y: 150))
    p.addQuadCurve(to: CGPoint(x: 308, y: 168), control: CGPoint(x: 308, y: 150))
    p.addCurve(to: CGPoint(x: 282, y: 256), control1: CGPoint(x: 308, y: 212), control2: CGPoint(x: 282, y: 230))
    p.addCurve(to: CGPoint(x: 308, y: 344), control1: CGPoint(x: 282, y: 282), control2: CGPoint(x: 308, y: 300))
    p.addQuadCurve(to: CGPoint(x: 290, y: 362), control: CGPoint(x: 308, y: 362))
    p.addLine(to: CGPoint(x: 222, y: 362))
    p.addQuadCurve(to: CGPoint(x: 204, y: 344), control: CGPoint(x: 204, y: 362))
    p.addCurve(to: CGPoint(x: 230, y: 256), control1: CGPoint(x: 204, y: 300), control2: CGPoint(x: 230, y: 282))
    p.addCurve(to: CGPoint(x: 204, y: 168), control1: CGPoint(x: 230, y: 230), control2: CGPoint(x: 204, y: 212))
    p.closeSubpath()
    // speaker notch (hole via even-odd)
    p.addRoundedRect(in: CGRect(x: 241, y: 166, width: 30, height: 9), cornerWidth: 4.5, cornerHeight: 4.5)
    return p
}

func barsPath() -> CGPath {
    let p = CGMutablePath()
    let y: CGFloat = 224, h: CGFloat = 64, w: CGFloat = 14, r: CGFloat = 7
    let xs: [CGFloat] = [150, 170, 328, 348] // left pair, right pair
    for x in xs {
        p.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r)
    }
    return p
}

// MARK: - Fill helpers
func fillSolid(_ ctx: CGContext, _ path: CGPath, _ color: CGColor, eo: Bool = false) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.fillPath(using: eo ? .evenOdd : .winding)
    ctx.restoreGState()
}

func fillGradient(_ ctx: CGContext, _ path: CGPath, _ c0: CGColor, _ c1: CGColor, eo: Bool = false) {
    ctx.saveGState()
    ctx.addPath(path)
    if eo { ctx.clip(using: .evenOdd) } else { ctx.clip() }
    let grad = CGGradient(colorsSpace: cs, colors: [c0, c1] as CFArray, locations: [0, 1])!
    let b = path.boundingBox
    ctx.drawLinearGradient(grad, start: CGPoint(x: b.minX, y: b.minY),
                           end: CGPoint(x: b.maxX, y: b.maxY), options: [])
    ctx.restoreGState()
}

// MARK: - Render
enum Style { case iconWhiteOnGradient; case markGradient }

func render(_ px: Int, style: Style) -> CGImage {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // y-down, 512-space
    ctx.translateBy(x: 0, y: CGFloat(px))
    ctx.scaleBy(x: 1, y: -1)
    ctx.scaleBy(x: CGFloat(px)/REF, y: CGFloat(px)/REF)

    let ring = ringOutline()
    let phone = phonePath()
    let bars = barsPath()

    switch style {
    case .iconWhiteOnGradient:
        // gradient square background
        let full = CGPath(rect: CGRect(x: 0, y: 0, width: REF, height: REF), transform: nil)
        fillGradient(ctx, full, bgTop, bgBot)
        // soft shadow under the mark for depth
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 26,
                      color: rgb(20, 0, 60, 0.35))
        fillSolid(ctx, ring, white)
        ctx.restoreGState()
        fillSolid(ctx, phone, white, eo: true)
        fillSolid(ctx, bars, white)
    case .markGradient:
        fillGradient(ctx, ring, markBlue, markViolet)
        fillGradient(ctx, phone, markBlue, markViolet, eo: true)
        fillSolid(ctx, bars, barCyan)
    }
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// MARK: - Outputs
let iconDir = "/Users/nihar/Rinkler/apps/ios/Rinkler/Assets.xcassets/AppIcon.appiconset"
let webApp = "/Users/nihar/Rinkler/apps/web/app"
let webPub = "/Users/nihar/Rinkler/apps/web/public"

let iconFiles: [(String, Int)] = [
    ("AppIcon-20x20@1x.png", 20), ("AppIcon-20x20@2x.png", 40), ("AppIcon-20x20@3x.png", 60),
    ("AppIcon-29x29@1x.png", 29), ("AppIcon-29x29@2x.png", 58), ("AppIcon-29x29@3x.png", 87),
    ("AppIcon-40x40@1x.png", 40), ("AppIcon-40x40@2x.png", 80), ("AppIcon-40x40@3x.png", 120),
    ("AppIcon-60x60@2x.png", 120), ("AppIcon-60x60@3x.png", 180),
    ("AppIcon-76x76@1x.png", 76), ("AppIcon-76x76@2x.png", 152),
    ("AppIcon-83.5x83.5@2x.png", 167), ("AppIcon-1024x1024.png", 1024),
]
for (name, px) in iconFiles {
    writePNG(render(px, style: .iconWhiteOnGradient), "\(iconDir)/\(name)")
}
// Web: favicon + apple touch (icon style), header mark (transparent gradient), OG.
writePNG(render(512, style: .iconWhiteOnGradient), "\(webApp)/icon.png")
writePNG(render(180, style: .iconWhiteOnGradient), "\(webApp)/apple-icon.png")
writePNG(render(512, style: .markGradient), "\(webPub)/rinkler-mark.png")
writePNG(render(1024, style: .iconWhiteOnGradient), "\(webPub)/rinkler-icon-1024.png")

print("done: \(iconFiles.count) iOS icons + 4 web assets")
