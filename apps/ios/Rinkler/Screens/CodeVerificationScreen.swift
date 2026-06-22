import SwiftUI

struct CodeVerificationScreen: View {
    let email: String
    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""
    @State private var service = MagicSignInService()
    @Environment(AuthStore.self) private var authStore
    var onVerified: () -> Void
    
    @FocusState private var isCodeFocused: Bool
    
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
                    
                    Text("enter your code.")
                        .font(RinklerFonts.subtitleItalic)
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }
                .padding(.leading, RinklerSpacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(spacing: RinklerSpacing.lg) {
                    Text("Code sent to \(email)")
                        .font(RinklerFonts.coolvetica(size: 16))
                        .foregroundStyle(RinklerColors.white60)
                        .padding(.horizontal, RinklerSpacing.buttonHorizontalPadding)
                    
                    VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                        Text("Verification Code")
                            .font(RinklerFonts.coolvetica(size: 18))
                            .foregroundStyle(.white)
                            .padding(.leading, RinklerSpacing.buttonHorizontalPadding)
                        
                        // Code input field
                        TextField("", text: $code, prompt: Text("000000")
                            .foregroundStyle(RinklerColors.white60))
                            .font(RinklerFonts.coolvetica(size: 32))
                            .foregroundStyle(.white)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .focused($isCodeFocused)
                            .onChange(of: code) { oldValue, newValue in
                                let digits = newValue.filter { $0.isNumber }
                                if digits.count <= 6 {
                                    if digits.count > 3 {
                                        let first = String(digits.prefix(3))
                                        let second = String(digits.dropFirst(3))
                                        code = "\(first) \(second)"
                                    } else {
                                        code = digits
                                    }
                                } else {
                                    code = oldValue
                                }
                            }
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
                        title: service.isLoading ? "VERIFYING…" : "VERIFY",
                        enabled: !service.isLoading && code.replacingOccurrences(of: " ", with: "").count == 6
                    ) {
                        Task {
                            do {
                                let isValid = try await service.verifyCode(code, email: email)
                                if isValid {
                                    authStore.refreshFromStoredSession()
                                    onVerified()
                                }
                            } catch {
                                // Error is handled by service.errorMessage
                            }
                        }
                    }
                    .padding(.horizontal, RinklerSpacing.xl)
                    
                    // Resend code option
                    Button(action: {
                        Task {
                            do {
                                try await service.sendMagicCode(email: email)
                            } catch {
                                // Error is handled by service.errorMessage
                            }
                        }
                    }) {
                        Text("Resend code")
                            .font(RinklerFonts.coolvetica(size: 16))
                            .foregroundStyle(RinklerColors.white60)
                    }
                    .padding(.top, RinklerSpacing.sm)
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
                .accessibilityLabel("Change email")
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFocused = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        CodeVerificationScreen(email: "user@example.com", onVerified: {})
    }
}
