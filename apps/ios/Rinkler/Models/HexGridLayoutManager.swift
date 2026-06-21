import Foundation

struct HexGridLayoutManager {
    let cellSpacing: CGFloat = 96

    var gridRadius: Int {
        // Computed externally; default to 1
        1
    }

    static func gridRadius(for appCount: Int) -> Int {
        // ring 0 = 1 slot (center), ring 1 = 6 more (7 total), ring 2 = 12 more (19 total)
        if appCount <= 7 { return 1 }
        return 2
    }

    // Pointy-top hex → screen point
    func hexToPoint(_ hex: HexCoordinate, center: CGPoint) -> CGPoint {
        let q = CGFloat(hex.q)
        let r = CGFloat(hex.r)
        // For pointy-top hexagons with center-to-center distance = cellSpacing
        // hex size = cellSpacing / sqrt(3)
        // x = size * sqrt(3) * (q + r/2) = cellSpacing * (q + r/2)
        // y = size * 3/2 * r = cellSpacing * sqrt(3) / 2 * r
        let x = cellSpacing * (q + r / 2)
        let y = cellSpacing * sqrt(3) / 2 * r
        return CGPoint(x: center.x + x, y: center.y + y)
    }

    // Screen point → nearest hex coordinate (with hex rounding)
    func nearestHex(to point: CGPoint, center: CGPoint) -> HexCoordinate {
        let dx = point.x - center.x
        let dy = point.y - center.y

        // Inverse of pointy-top hex conversion
        // Given: x = cellSpacing * (q + r/2), y = cellSpacing * sqrt(3)/2 * r
        // Solving: r = 2y / (cellSpacing * sqrt(3))
        //          q = x/cellSpacing - r/2 = (sqrt(3) * x - y) / (cellSpacing * sqrt(3))
        let sqrt3 = sqrt(3.0)
        let q = (dx - dy / sqrt3) / cellSpacing
        let r = (2.0 * dy) / (cellSpacing * sqrt3)

        return hexRound(q: Double(q), r: Double(r))
    }

    private func hexRound(q: Double, r: Double) -> HexCoordinate {
        let s = -q - r
        var rq = q.rounded()
        var rr = r.rounded()
        let rs = s.rounded()

        let qDiff = abs(rq - q)
        let rDiff = abs(rr - r)
        let sDiff = abs(rs - s)

        if qDiff > rDiff && qDiff > sDiff {
            rq = -rr - rs
        } else if rDiff > sDiff {
            rr = -rq - rs
        }

        return HexCoordinate(q: Int(rq), r: Int(rr))
    }
}
