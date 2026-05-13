import SwiftUI

struct HeaderBar: View {
    var title: String = "RINKLER"

    var body: some View {
        HStack {
            Text(title)
                .font(BubbleFonts.headerTitle)
                .foregroundStyle(.white)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        VStack {
            HeaderBar()
            Spacer()
        }
    }
}
