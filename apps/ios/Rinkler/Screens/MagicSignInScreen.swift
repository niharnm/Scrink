import SwiftUI

/// Sign back in — offers the same options as onboarding (Apple, Google, email)
/// so a returning user can use whatever they signed up with.
struct MagicSignInScreen: View {
    @Environment(\.dismiss) private var dismiss
    var onSignedIn: () -> Void = {}

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RINKLER")
                            .font(RinklerFonts.sans(13, .semibold)).tracking(3)
                            .foregroundStyle(RinklerColors.signalTextDim)
                        Text("Welcome back")
                            .font(RinklerFonts.sans(30, .bold))
                            .foregroundStyle(RinklerColors.signalText)
                        Text("Sign in and your rules, streak, and limits come right back.")
                            .font(RinklerFonts.sans(15, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, RinklerSpacing.xl)

                    AuthOptionsView(onSuccess: onSignedIn)
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
        }
    }
}

#Preview {
    NavigationStack { MagicSignInScreen() }
        .environment(AuthStore())
}
