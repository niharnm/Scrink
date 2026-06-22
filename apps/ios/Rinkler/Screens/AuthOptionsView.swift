import SwiftUI
import AuthenticationServices

/// One shared set of sign-in options so onboarding and the sign-in screen always
/// match: Apple, Google, and an email code (inline). On success it refreshes the
/// auth state and calls `onSuccess`.
struct AuthOptionsView: View {
    var onSuccess: () -> Void

    @Environment(AuthStore.self) private var authStore
    @State private var social = SocialAuthService()
    @State private var magic = MagicSignInService()
    @State private var email = ""
    @State private var code = ""
    @State private var codeSent = false

    private var busy: Bool { social.isLoading || magic.isLoading }

    var body: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.continue) { request in
                social.configureAppleRequest(request)
            } onCompletion: { result in
                Task { if await social.handleApple(result) { finish() } }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(busy)

            Button { Task { if await social.signInWithGoogle() { finish() } } } label: {
                HStack(spacing: 10) {
                    GoogleGlyph()
                    Text("Continue with Google")
                        .font(RinklerFonts.sans(17, .semibold))
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(busy)

            HStack(spacing: 10) {
                divider
                Text("or").font(RinklerFonts.sans(12, .medium)).foregroundStyle(RinklerColors.signalTextFaint)
                divider
            }
            .padding(.vertical, 2)

            if !codeSent {
                emailField
                Button {
                    Task { try? await magic.sendMagicCode(email: email); codeSent = magic.isCodeSent }
                } label: {
                    Text("Email me a code")
                        .font(RinklerFonts.sans(16, .semibold))
                        .foregroundStyle(RinklerColors.signalText)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(busy || email.isEmpty)
            } else {
                Text("Code sent to \(magic.email)")
                    .font(RinklerFonts.sans(12, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                codeField
                Button {
                    Task { if (try? await magic.verifyCode(code, email: magic.email)) == true { finish() } }
                } label: {
                    Text("Verify & sign in")
                        .font(RinklerFonts.sans(16, .semibold))
                        .foregroundStyle(RinklerColors.signalOnInk)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RinklerColors.signalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(busy || code.filter(\.isNumber).count < 6)
                Button("Use a different email") { codeSent = false; code = ""; magic.reset() }
                    .font(RinklerFonts.sans(12, .medium))
                    .foregroundStyle(RinklerColors.signalTextDim)
            }

            if busy { ProgressView().tint(RinklerColors.signalTextDim).padding(.top, 2) }
            if let err = social.errorMessage ?? magic.errorMessage {
                Text(err)
                    .font(RinklerFonts.sans(13, .regular))
                    .foregroundStyle(RinklerColors.signalWarning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emailField: some View {
        TextField("", text: $email, prompt: Text("you@email.com").foregroundStyle(RinklerColors.signalTextFaint))
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .font(RinklerFonts.sans(16, .regular))
            .foregroundStyle(RinklerColors.signalText)
            .padding(14)
            .background(RinklerColors.signalCard)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var codeField: some View {
        TextField("", text: $code, prompt: Text("000000").foregroundStyle(RinklerColors.signalTextFaint))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(RinklerFonts.mono(22, .medium))
            .foregroundStyle(RinklerColors.signalText)
            .padding(14)
            .background(RinklerColors.signalCard)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var divider: some View { Rectangle().fill(RinklerColors.signalBorder).frame(height: 1) }

    private func finish() {
        authStore.refreshFromStoredSession()
        onSuccess()
    }
}
