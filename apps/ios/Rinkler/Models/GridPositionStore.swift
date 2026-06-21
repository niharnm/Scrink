import Foundation
import Observation

@Observable
final class GridPositionStore {
    private static let userDefaultsKey = "hexGridPositions"

    private(set) var positions: [String: HexCoordinate] = [:]

    init() {
        load()
    }

    func position(for appId: String) -> HexCoordinate? {
        positions[appId]
    }

    func occupant(at hex: HexCoordinate) -> String? {
        positions.first { $0.value == hex }?.key
    }

    func assignPosition(appId: String, to hex: HexCoordinate) {
        // If another app occupies this slot, swap them
        if let existingAppId = occupant(at: hex), existingAppId != appId {
            let currentPos = positions[appId]
            positions[existingAppId] = currentPos
        }
        positions[appId] = hex
        save()
    }

    func assignDefaultPositions(for apps: [String]) {
        guard !apps.isEmpty else { return }

        let needsDefaults = apps.contains { positions[$0] == nil }
        guard needsDefaults else { return }

        // First app goes to origin
        if positions[apps[0]] == nil {
            positions[apps[0]] = .origin
        }

        // Remaining apps fill ring-1 slots
        let ring1 = HexCoordinate.hexesInRadius(1).filter { $0 != .origin }
        var slotIndex = 0
        for i in 1..<apps.count {
            if positions[apps[i]] == nil {
                if slotIndex < ring1.count {
                    positions[apps[i]] = ring1[slotIndex]
                    slotIndex += 1
                } else {
                    // Overflow into ring 2
                    let ring2 = HexCoordinate.hexesInRadius(2).filter { hex in
                        hex.distance(to: .origin) == 2
                    }
                    let ring2Index = slotIndex - ring1.count
                    if ring2Index < ring2.count {
                        positions[apps[i]] = ring2[ring2Index]
                    }
                    slotIndex += 1
                }
            }
        }

        save()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([String: HexCoordinate].self, from: data) {
            positions = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
