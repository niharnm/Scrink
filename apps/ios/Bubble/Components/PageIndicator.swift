import SwiftUI

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: BubbleSpacing.dotSpacing) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? BubbleColors.skyBlue : BubbleColors.skyBlue.opacity(0.4))
                    .frame(width: BubbleSpacing.dotSize, height: BubbleSpacing.dotSize)
            }
        }
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        PageIndicator(totalPages: 3, currentPage: 0)
    }
}
