import Foundation

struct HexCoordinate: Codable, Hashable {
    let q: Int
    let r: Int

    static let origin = HexCoordinate(q: 0, r: 0)

    var s: Int { -q - r }

    func distance(to other: HexCoordinate) -> Int {
        (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2
    }

    static let directions: [HexCoordinate] = [
        HexCoordinate(q: 1, r: 0),
        HexCoordinate(q: 1, r: -1),
        HexCoordinate(q: 0, r: -1),
        HexCoordinate(q: -1, r: 0),
        HexCoordinate(q: -1, r: 1),
        HexCoordinate(q: 0, r: 1)
    ]

    func neighbor(in direction: Int) -> HexCoordinate {
        let d = HexCoordinate.directions[direction % 6]
        return HexCoordinate(q: q + d.q, r: r + d.r)
    }

    var neighbors: [HexCoordinate] {
        HexCoordinate.directions.map { d in
            HexCoordinate(q: q + d.q, r: r + d.r)
        }
    }

    static func hexesInRadius(_ radius: Int) -> [HexCoordinate] {
        var results: [HexCoordinate] = []
        for q in -radius...radius {
            for r in max(-radius, -q - radius)...min(radius, -q + radius) {
                results.append(HexCoordinate(q: q, r: r))
            }
        }
        return results
    }
}
