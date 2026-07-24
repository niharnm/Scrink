import Foundation
import Observation
import AuthenticationServices
import CryptoKit
import UIKit

/// Coordinates the two social sign-in paths used during onboarding:
///
/// - **Apple** — native `SignInWithAppleButton`. We generate a random nonce,
///   send its SHA-256 to Apple, then hand the raw nonce + identity token to
///   Supabase's `id_token` grant.
/// - **Google** — PKCE through `ASWebAuthenticationSession` against Supabase's
///   OAuth `authorize` endpoint, returning a one-time code to the app's
///   `rinkler://` callback. No extra SDK dependency required.
///
/// Both paths end with a Supabase session persisted to the keychain; the caller
/// then refreshes `AuthStore` from that stored session.
@Observable
@MainActor
final class SocialAuthService {
    var isLoading = false
    var errorMessage: String?

    /// The raw nonce for the in-flight Apple request.
    private var currentNonce: String?
    /// Retained so the system callback can fire; the provider holds it weakly.
    private var webSession: ASWebAuthenticationSession?
    private let presenter = WebAuthPresenter()

    private let callbackScheme = "rinkler"

    // MARK: - Apple

    /// Configures the request the `SignInWithAppleButton` submits.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Handles the button's completion result and exchanges with Supabase.
    /// Returns `true` only when a session was established.
    func handleApple(_ result: Result<ASAuthorization, Error>) async -> Bool {
        errorMessage = nil
        switch result {
        case .failure(let error):
            // A user-initiated cancel isn't an error worth surfacing.
            if (error as? ASAuthorizationError)?.code == .canceled { return false }
            errorMessage = error.localizedDescription
            return false

        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Apple sign-in didn't return an identity token. Try again."
                return false
            }

            isLoading = true
            defer { isLoading = false }
            do {
                _ = try await SupabaseAuthClient.shared.signInWithApple(idToken: idToken, nonce: nonce)
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        }
    }

    // MARK: - Google

    func signInWithGoogle() async -> Bool {
        errorMessage = nil
        let codeVerifier = Self.randomNonce(length: 64)
        let codeChallenge = Self.pkceChallenge(for: codeVerifier)
        guard let authURL = SupabaseAuthClient.shared.oauthAuthorizeURL(
            provider: "google",
            redirectTo: "\(callbackScheme)://auth-callback",
            codeChallenge: codeChallenge
        ) else {
            errorMessage = "Google sign-in isn't configured yet."
            return false
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let callback = try await startWebAuth(url: authURL)
            _ = try await SupabaseAuthClient.shared.completeOAuth(
                callbackURL: callback,
                codeVerifier: codeVerifier
            )
            return true
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func startWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: SupabaseAuthError.invalidResponse)
                }
            }
            session.presentationContextProvider = presenter
            // Ephemeral: don't share or leave behind the system Safari cookie jar,
            // so sign-in always shows an account chooser and no Google/Apple
            // session persists on the device after onboarding.
            session.prefersEphemeralWebBrowserSession = true
            webSession = session
            if !session.start() {
                continuation.resume(throwing: SupabaseAuthError.requestFailed("Couldn't open the sign-in window."))
            }
        }
    }

    // MARK: - Nonce helpers

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &random) == errSecSuccess else { continue }
            if random < UInt8(charset.count) {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func pkceChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8)))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

/// Supplies the window `ASWebAuthenticationSession` anchors to. Kept separate
/// from the `@Observable` service so the service stays a plain value-semantics
/// observer rather than an `NSObject`.
private final class WebAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
    }
}
