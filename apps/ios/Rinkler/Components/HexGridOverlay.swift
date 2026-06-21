import SwiftUI

struct HexGridOverlay: View {
    let gridSlots: [HexCoordinate]
    let occupiedSlots: Set<HexCoordinate>
    let highlightedSlot: HexCoordinate?
    let center: CGPoint
    let layoutManager: HexGridLayoutManager

    var body: some View {
        ForEach(Array(gridSlots.enumerated()), id: \.offset) { _, hex in
            let point = layoutManager.hexToPoint(hex, center: center)
            let isOccupied = occupiedSlots.contains(hex)
            let isHighlighted = highlightedSlot == hex

            Circle()
                .fill(Color.white.opacity(fillOpacity(isOccupied: isOccupied, isHighlighted: isHighlighted)))
                .frame(width: slotSize(isHighlighted: isHighlighted),
                       height: slotSize(isHighlighted: isHighlighted))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(strokeOpacity(isOccupied: isOccupied, isHighlighted: isHighlighted)), lineWidth: 2)
                )
                .position(point)
                .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        }
    }

    private func fillOpacity(isOccupied: Bool, isHighlighted: Bool) -> Double {
        if isHighlighted { return 0.25 }
        if isOccupied { return 0.1 }
        return 0.05
    }

    private func strokeOpacity(isOccupied: Bool, isHighlighted: Bool) -> Double {
        if isHighlighted { return 0.8 }
        if isOccupied { return 0.3 }
        return 0.15
    }

    private func slotSize(isHighlighted: Bool) -> CGFloat {
        isHighlighted ? 74 : 68
    }
}
