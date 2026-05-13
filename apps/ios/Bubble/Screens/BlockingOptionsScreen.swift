import SwiftUI

struct BlockingOptionsScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let appId: String

    private var app: BlockedApp? {
        store.app(for: appId)
    }

    var body: some View {
        ZStack {
            SkyBackgroundView()

            VStack(spacing: 0) {
                HeaderBar()

                Spacer()

                if let app {
                    DialSelector(
                        app: app,
                        onToggleOption: { optionId in
                            store.toggleOption(appId: appId, optionId: optionId)
                        }
                    )

                    Text(app.name)
                        .font(BubbleFonts.headerTitle)
                        .foregroundStyle(.white)
                        .padding(.top, BubbleSpacing.xl)
                }

                Spacer()
            }

            // Back button - matching the design (blue arrow on left)
            VStack {
                Spacer()
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(BubbleColors.skyBlue)
                            .clipShape(Circle())
                    }
                    .padding(.leading, BubbleSpacing.lg + 5)
                    .padding(.bottom, BubbleSpacing.xxl - 10)

                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        BlockingOptionsScreen(appId: "instagram")
            .environment(AppStore())
    }
}
