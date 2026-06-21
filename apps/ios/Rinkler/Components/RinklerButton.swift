import SwiftUI

struct RinklerButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RinklerFonts.buttonText)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: RinklerSpacing.buttonHeight)
                .background(RinklerColors.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: RinklerSpacing.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: RinklerSpacing.buttonCornerRadius)
                        .strokeBorder(Color.white, lineWidth: 2)
                )
        }
        .padding(.horizontal, RinklerSpacing.buttonHorizontalPadding)
    }
}

#Preview {
    ZStack {
        RinklerColors.skyGradient.ignoresSafeArea()
        RinklerButton(title: "GO") {}
    }
}
