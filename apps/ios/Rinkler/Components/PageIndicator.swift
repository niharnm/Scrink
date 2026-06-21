import SwiftUI

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: RinklerSpacing.dotSpacing) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? RinklerColors.skyBlue : RinklerColors.skyBlue.opacity(0.4))
                    .frame(width: RinklerSpacing.dotSize, height: RinklerSpacing.dotSize)
            }
        }
    }
}

#Preview {
    ZStack {
        RinklerColors.skyGradient.ignoresSafeArea()
        PageIndicator(totalPages: 3, currentPage: 0)
    }
}
