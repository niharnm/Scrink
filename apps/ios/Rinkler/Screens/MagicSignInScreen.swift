import SwiftUI

struct MagicSignInScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var service = MagicSignInService()
    var onCodeSent: (String) -> Void
    var onContinueOffline: () -> Void = {}
    
    var body: some View {
        ZStack {
            SkyBackgroundView()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height / 6)
                
                VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
                    Text("RINKLER")
                        .font(RinklerFonts.titleLarge)
                        .foregroundStyle(.white)
                    
                    Text("sign in with email.")
                        .font(RinklerFonts.subtitleItalic)
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }
                .padding(.leading, RinklerSpacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(spacing: RinklerSpacing.lg) {
                    VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                        Text("Email")
                            .font(RinklerFonts.coolvetica(size: 18))
                            .foregroundStyle(.white)
                            .padding(.leading, RinklerSpacing.buttonHorizontalPadding)
                        
                        TextField("", text: $email, prompt: Text("Enter your email")
                            .foregroundStyle(RinklerColors.white60))
                            .font(RinklerFonts.coolvetica(size: 20))
                            .foregroundStyle(.white)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(RinklerSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: RinklerSpacing.buttonCornerRadius)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RinklerSpacing.buttonCornerRadius)
                                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, RinklerSpacing.buttonHorizontalPadding)
                    }
                    
                    if let errorMessage = service.errorMessage {
                        Text(errorMessage)
                            .font(RinklerFonts.coolvetica(size: 14))
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal, RinklerSpacing.buttonHorizontalPadding)
                    }
                    
                    AuroraButton(
                        title: service.isLoading ? "SENDING…" : "SEND CODE",
                        enabled: !service.isLoading && !email.isEmpty
                    ) {
                        Task {
                            do {
                                try await service.sendMagicCode(email: email)
                                onCodeSent(service.email)
                            } catch {
                                // Error is handled by service.errorMessage
                            }
                        }
                    }
                    .padding(.horizontal, RinklerSpacing.xl)

                    Button(action: onContinueOffline) {
                        Text("Continue without cloud sync")
                            .font(RinklerFonts.coolvetica(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RinklerSpacing.sm)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, RinklerSpacing.buttonHorizontalPadding)
                }
                
                Spacer()
                    .frame(height: RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    BackArrowView(color: .white)
                }
                .accessibilityLabel("Back")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MagicSignInScreen(onCodeSent: { _ in })
    }
    .environment(AuthStore())
}
