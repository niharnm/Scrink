import SwiftUI

struct MagicSignInScreen: View {
    @State private var email: String = ""
    @State private var service = MagicSignInService()
    var onCodeSent: (String) -> Void
    
    var body: some View {
        ZStack {
            SkyBackgroundView()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height / 6)
                
                // Title block
                VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
                    Text("RINKLER")
                        .font(BubbleFonts.titleLarge)
                        .foregroundStyle(.white)
                    
                    Text("sign in with email.")
                        .font(BubbleFonts.subtitleItalic)
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }
                .padding(.leading, BubbleSpacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Email input section
                VStack(spacing: BubbleSpacing.lg) {
                    VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
                        Text("Email")
                            .font(BubbleFonts.coolvetica(size: 18))
                            .foregroundStyle(.white)
                            .padding(.leading, BubbleSpacing.buttonHorizontalPadding)
                        
                        TextField("", text: $email, prompt: Text("Enter your email")
                            .foregroundStyle(BubbleColors.white60))
                            .font(BubbleFonts.coolvetica(size: 20))
                            .foregroundStyle(.white)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(BubbleSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
                                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, BubbleSpacing.buttonHorizontalPadding)
                    }
                    
                    // Error message
                    if let errorMessage = service.errorMessage {
                        Text(errorMessage)
                            .font(BubbleFonts.coolvetica(size: 14))
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal, BubbleSpacing.buttonHorizontalPadding)
                    }
                    
                    // Send code button
                    Button(action: {
                        Task {
                            do {
                                try await service.sendMagicCode(email: email)
                                onCodeSent(email)
                            } catch {
                                // Error is handled by service.errorMessage
                            }
                        }
                    }) {
                        HStack {
                            if service.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("SEND CODE")
                                    .font(BubbleFonts.buttonText)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: BubbleSpacing.buttonHeight)
                        .background(service.isLoading || email.isEmpty ? Color.gray.opacity(0.5) : BubbleColors.skyBlue)
                        .clipShape(RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
                                .strokeBorder(Color.white, lineWidth: 2)
                        )
                    }
                    .disabled(service.isLoading || email.isEmpty)
                    .padding(.horizontal, BubbleSpacing.buttonHorizontalPadding)
                }
                
                Spacer()
                    .frame(height: BubbleSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        MagicSignInScreen(onCodeSent: { _ in })
    }
    .environment(AuthStore())
}
