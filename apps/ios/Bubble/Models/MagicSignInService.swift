import Foundation
import Observation

@Observable
class MagicSignInService {
    var email: String = ""
    var code: String = ""
    var isCodeSent: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    func sendMagicCode(email: String) async throws {
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            throw MagicSignInError.invalidEmail
        }

        do {
            try await SupabaseAuthClient.shared.sendMagicCode(email: email)
            self.email = email
            self.isCodeSent = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw MagicSignInError.networkError
        }

        isLoading = false
    }

    func verifyCode(_ code: String, email: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        let cleanedCode = code.replacingOccurrences(of: " ", with: "")
        guard cleanedCode.count == 6, cleanedCode.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Please enter a valid 6-digit code"
            isLoading = false
            throw MagicSignInError.invalidCode
        }

        do {
            _ = try await SupabaseAuthClient.shared.verifyEmailOTP(email: email, token: cleanedCode)
            self.email = email
            self.code = cleanedCode
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
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
