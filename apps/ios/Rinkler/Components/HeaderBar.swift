import SwiftUI

struct HeaderBar: View {
    var title: String = "RINKLER"

    var body: some View {
        HStack {
            Text(title)
                .font(RinklerFonts.headerTitle)
                .foregroundStyle(.white)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        RinklerColors.skyGradient.ignoresSafeArea()
        VStack {
            HeaderBar()
            Spacer()
        }
    }
}
