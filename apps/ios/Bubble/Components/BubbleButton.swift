import SwiftUI

struct BubbleButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BubbleFonts.buttonText)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: BubbleSpacing.buttonHeight)
                .background(BubbleColors.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
                        .strokeBorder(Color.white, lineWidth: 2)
                )
        }
        .padding(.horizontal, BubbleSpacing.buttonHorizontalPadding)
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        BubbleButton(title: "GO") {}
    }
}
