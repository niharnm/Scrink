import SwiftUI

struct CodeVerificationScreen: View {
    let email: String
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
                
                // Title block
                VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
                    Text("BUBBLE")
                        .font(BubbleFonts.titleLarge)
                        .foregroundStyle(.white)
                    
                    Text("enter your code.")
                        .font(BubbleFonts.subtitleItalic)
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }
                .padding(.leading, BubbleSpacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Code input section
                VStack(spacing: BubbleSpacing.lg) {
                    // Email confirmation
                    Text("Code sent to \(email)")
                        .font(BubbleFonts.coolvetica(size: 16))
                        .foregroundStyle(BubbleColors.white60)
                        .padding(.horizontal, BubbleSpacing.buttonHorizontalPadding)
                    
                    VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
                        Text("Verification Code")
                            .font(BubbleFonts.coolvetica(size: 18))
                            .foregroundStyle(.white)
                            .padding(.leading, BubbleSpacing.buttonHorizontalPadding)
                        
                        // Code input field
                        TextField("", text: $code, prompt: Text("000000")
                            .foregroundStyle(BubbleColors.white60))
                            .font(BubbleFonts.coolvetica(size: 32))
                            .foregroundStyle(.white)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .focused($isCodeFocused)
                            .onChange(of: code) { oldValue, newValue in
                                // Limit to 6 digits and format with spaces
                                let digits = newValue.filter { $0.isNumber }
                                if digits.count <= 6 {
                                    // Format as XXX XXX
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
                    
                    // Verify button
                    Button(action: {
                        Task {
                            do {
                                let isValid = try await service.verifyCode(code)
                                if isValid {
                                    authStore.login(email: email)
                                    onVerified()
                                }
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
                                Text("VERIFY")
                                    .font(BubbleFonts.buttonText)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: BubbleSpacing.buttonHeight)
                        .background(service.isLoading || code.replacingOccurrences(of: " ", with: "").count != 6 ? Color.gray.opacity(0.5) : BubbleColors.skyBlue)
                        .clipShape(RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
                                .strokeBorder(Color.white, lineWidth: 2)
                        )
                    }
                    .disabled(service.isLoading || code.replacingOccurrences(of: " ", with: "").count != 6)
                    .padding(.horizontal, BubbleSpacing.buttonHorizontalPadding)
                    
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
                            .font(BubbleFonts.coolvetica(size: 16))
                            .foregroundStyle(BubbleColors.white60)
                    }
                    .padding(.top, BubbleSpacing.sm)
                }
                
                Spacer()
                    .frame(height: BubbleSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Auto-focus the code input
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
