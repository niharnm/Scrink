import Foundation
import Observation

@Observable
@MainActor
class MagicSignInService {
    var email: String = ""
    var code: String = ""
    var isCodeSent: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    func sendMagicCode(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard isValidEmail(normalizedEmail) else {
            errorMessage = "Please enter a valid email address"
            throw MagicSignInError.invalidEmail
        }

        do {
            try await SupabaseAuthClient.shared.sendMagicCode(email: normalizedEmail)
            self.email = normalizedEmail
            self.isCodeSent = true
        } catch {
            errorMessage = error.localizedDescription
            throw MagicSignInError.networkError
        }
    }

    func verifyCode(_ code: String, email: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cleanedCode = code.replacingOccurrences(of: " ", with: "")
        guard cleanedCode.count == 6, cleanedCode.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Please enter a valid 6-digit code"
            throw MagicSignInError.invalidCode
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            _ = try await SupabaseAuthClient.shared.verifyEmailOTP(email: normalizedEmail, token: cleanedCode)
            self.email = normalizedEmail
            self.code = cleanedCode
            return true
        } catch {
            errorMessage = error.localizedDescription
            throw MagicSignInError.invalidCode
        }
    }

    func reset() {
        email = ""
        code = ""
        isCodeSent = false
        isLoading = false
        errorMessage = nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

enum MagicSignInError: LocalizedError {
    case invalidEmail
    case invalidCode
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidCode:
            return "Please enter a valid 6-digit code"
        case .networkError:
            return "Network error. Please try again."
        }
    }
}
