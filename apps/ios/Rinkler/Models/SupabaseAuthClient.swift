import Foundation
import Security

struct SupabaseAuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let expiresAt: Date?
    let userID: String
    let email: String

    var shouldRefresh: Bool {
        guard let expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow < 120
    }
}

enum SupabaseAuthError: LocalizedError {
    case missingConfiguration
    case notAuthenticated
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Missing Supabase configuration."
        case .notAuthenticated:
            return "Please sign in again."
        case .invalidResponse:
            return "Supabase returned an invalid response."
        case .requestFailed(let message):
            return message
        }
    }
}

final class SupabaseAuthClient {
    static let shared = SupabaseAuthClient()

    private struct Configuration {
        let baseURL: URL
        let anonKey: String
    }

    private let keychainService = "com.rinkler.app.auth"
    private let keychainAccount = "supabaseSession"
    private let configuration: Configuration?
    private let urlSession: URLSession

    init(
        urlSession: URLSession = .shared,
        bundle: Bundle = .main
    ) {
        if let urlString = bundle.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: urlString),
              let key = bundle.infoDictionary?["SUPABASE_KEY"] as? String,
              !key.isEmpty {
            self.configuration = Configuration(baseURL: url, anonKey: key)
        } else {
            self.configuration = nil
        }

        self.urlSession = urlSession
    }

    /// Emails a one-time login code. `createUser` defaults to true for the
    /// normal sign-in/sign-up flow; the account-deletion re-auth passes false so
    /// a mistyped/diverged email fails loudly instead of provisioning a phantom.
    func sendMagicCode(email: String, createUser: Bool = true) async throws {
        var request = try authRequest(path: "otp")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(OTPRequest(email: email, createUser: createUser))

        try await send(request)
    }

    func verifyEmailOTP(email: String, token: String) async throws -> SupabaseAuthSession {
        var request = try authRequest(path: "verify")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(VerifyOTPRequest(email: email, token: token))

        let response = try await send(request, decodeAs: VerifyOTPResponse.self)
        guard let accessToken = response.accessToken,
              let userID = response.user.id else {
            throw SupabaseAuthError.invalidResponse
        }

        let session = SupabaseAuthSession(
            accessToken: accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            expiresAt: response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) },
            userID: userID,
            email: response.user.email ?? email
        )
        try saveSession(session)
        return session
    }

    func authenticatedRESTRequest(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = []
    ) async throws -> (request: URLRequest, session: SupabaseAuthSession) {
        guard let configuration else {
            throw SupabaseAuthError.missingConfiguration
        }

        let session = try await validSession()
        let baseURL = configuration.baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(path)

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidResponse
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return (request, session)
    }

    func signOut() async {
        if let session = loadSession() {
            if var request = try? authRequest(path: "logout") {
                request.httpMethod = "POST"
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                _ = try? await urlSession.data(for: request)
            }
        }

        clearSession()
        Self.purgeLocalArtifacts()
    }

    func loadSession() -> SupabaseAuthSession? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(SupabaseAuthSession.self, from: data)
    }

    private func validSession() async throws -> SupabaseAuthSession {
        guard let session = loadSession() else {
            throw SupabaseAuthError.notAuthenticated
        }

        guard session.shouldRefresh else {
            return session
        }

        return try await refreshSession(session)
    }

    private func refreshSession(_ session: SupabaseAuthSession) async throws -> SupabaseAuthSession {
        guard let refreshToken = session.refreshToken, !refreshToken.isEmpty else {
            clearSession()
            throw SupabaseAuthError.notAuthenticated
        }

        var request = try authRequest(path: "token")
        guard let tokenURL = request.url,
              var components = URLComponents(url: tokenURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        request.url = components.url
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(RefreshSessionRequest(refreshToken: refreshToken))

        let response = try await send(request, decodeAs: VerifyOTPResponse.self)
        guard let accessToken = response.accessToken,
              let userID = response.user.id else {
            clearSession()
            throw SupabaseAuthError.invalidResponse
        }

        let refreshed = SupabaseAuthSession(
            accessToken: accessToken,
            refreshToken: response.refreshToken ?? refreshToken,
            expiresIn: response.expiresIn,
            expiresAt: response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) },
            userID: userID,
            email: response.user.email ?? session.email
        )
        try saveSession(refreshed)
        return refreshed
    }

    private func saveSession(_ session: SupabaseAuthSession) throws {
        let data = try JSONEncoder().encode(session)
        SecItemDelete(keychainQuery() as CFDictionary)

        var item = keychainQuery()
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SupabaseAuthError.requestFailed("Could not save your session securely.")
        }
    }

    private func clearSession() {
        SecItemDelete(keychainQuery() as CFDictionary)
    }

    /// Local-only session wipe (no network round-trip). The iOS Keychain
    /// survives app deletion, so this is called on the first launch after a
    /// fresh (re)install to make a reinstall a true reset.
    func clearLocalSession() {
        clearSession()
    }

    /// Deletes on-device browsing artifacts (tunnel traffic stats + log) and the
    /// upload bookkeeping from the App Group container, so signing out or
    /// deleting the account leaves behind no domain-visit history. (The default
    /// file-protection class is the strongest one compatible with a tunnel that
    /// must keep writing while the device is locked.)
    static func purgeLocalArtifacts() {
        let fm = FileManager.default
        if let container = fm.containerURL(forSecurityApplicationGroupIdentifier: RinklerConstants.appGroupID) {
            for name in [RinklerConstants.statsFileName, RinklerConstants.logFileName] {
                try? fm.removeItem(at: container.appendingPathComponent(name))
            }
        }
        UserDefaults(suiteName: RinklerConstants.appGroupID)?
            .removeObject(forKey: "uploadedTrafficEventClientIDs")
    }

    /// Permanently deletes the signed-in user's own account via the
    /// `delete_current_user` RPC (SECURITY DEFINER; only ever deletes the
    /// caller's `auth.uid()` row, cascading all their data). The caller MUST
    /// re-verify identity with a fresh emailed OTP immediately before this.
    func deleteCurrentUser() async throws {
        var (request, _) = try await authenticatedRESTRequest(path: "rpc/delete_current_user", method: "POST")
        request.httpBody = Data("{}".utf8)
        let (_, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SupabaseAuthError.requestFailed("Account deletion failed (\(http.statusCode)).")
        }
    }

    private func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
    }

    private func authRequest(path: String) throws -> URLRequest {
        guard let configuration else {
            throw SupabaseAuthError.missingConfiguration
        }

        let url = configuration.baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send(_ request: URLRequest) async throws {
        let (_, response) = try await perform(request)
        guard (200..<300).contains(response.statusCode) else {
            throw SupabaseAuthError.requestFailed("Request failed with status \(response.statusCode).")
        }
    }

    private func send<Response: Decodable>(_ request: URLRequest, decodeAs responseType: Response.Type) async throws -> Response {
        let (data, response) = try await perform(request)
        guard (200..<300).contains(response.statusCode) else {
            let message = (try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data).message)
                ?? "Request failed with status \(response.statusCode)."
            throw SupabaseAuthError.requestFailed(message)
        }

        return try JSONDecoder().decode(responseType, from: data)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        return (data, httpResponse)
    }
}

// MARK: - Social sign-in (Apple / Google)

extension SupabaseAuthClient {
    /// Native Sign in with Apple: exchanges Apple's identity token for a Supabase
    /// session via the `id_token` grant. `nonce` is the *raw* (un-hashed) nonce —
    /// Apple embeds its SHA-256 in the token and Supabase re-hashes this to verify.
    func signInWithApple(idToken: String, nonce: String) async throws -> SupabaseAuthSession {
        var request = try authRequest(path: "token")
        guard let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]
        request.url = components.url
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(
            IDTokenRequest(provider: "apple", idToken: idToken, nonce: nonce)
        )

        let response = try await send(request, decodeAs: VerifyOTPResponse.self)
        guard let accessToken = response.accessToken, let userID = response.user.id else {
            throw SupabaseAuthError.invalidResponse
        }

        let session = SupabaseAuthSession(
            accessToken: accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            expiresAt: response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) },
            userID: userID,
            email: response.user.email ?? ""
        )
        try saveSession(session)
        return session
    }

    /// Builds the Supabase OAuth authorize URL for a provider (e.g. "google"),
    /// driven through `ASWebAuthenticationSession`. `redirectTo` is the app's
    /// custom-scheme callback (must be allow-listed in the Supabase dashboard).
    func oauthAuthorizeURL(provider: String, redirectTo: String) -> URL? {
        guard let configuration else { return nil }
        let base = configuration.baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent("authorize")
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "provider", value: provider),
            URLQueryItem(name: "redirect_to", value: redirectTo),
        ]
        return components.url
    }

    /// Completes an OAuth implicit-flow redirect: parses the tokens from the
    /// callback URL fragment, derives the user id/email from the JWT, and stores
    /// the session.
    func completeOAuth(callbackURL: URL) throws -> SupabaseAuthSession {
        guard let fragment = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.fragment else {
            throw SupabaseAuthError.invalidResponse
        }

        var params: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            params[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
        }

        if let error = params["error_description"] ?? params["error"] {
            throw SupabaseAuthError.requestFailed(error.replacingOccurrences(of: "+", with: " "))
        }
        guard let accessToken = params["access_token"] else {
            throw SupabaseAuthError.invalidResponse
        }

        let claims = Self.decodeJWTClaims(accessToken)
        let expiresIn = params["expires_in"].flatMap { Int($0) }
        let session = SupabaseAuthSession(
            accessToken: accessToken,
            refreshToken: params["refresh_token"],
            expiresIn: expiresIn,
            expiresAt: expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) },
            userID: (claims?["sub"] as? String) ?? "",
            email: (claims?["email"] as? String) ?? ""
        )
        try saveSession(session)
        return session
    }

    /// Decodes the (unverified) payload claims of a JWT — used only to read the
    /// `sub`/`email` for display; the token itself is what Supabase trusts.
    private static func decodeJWTClaims(_ jwt: String) -> [String: Any]? {
        let segments = jwt.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}

private struct IDTokenRequest: Encodable {
    let provider: String
    let idToken: String
    let nonce: String

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case nonce
    }
}

private struct OTPRequest: Encodable {
    let email: String
    var createUser = true

    enum CodingKeys: String, CodingKey {
        case email
        case createUser = "create_user"
    }
}

private struct VerifyOTPRequest: Encodable {
    let email: String
    let token: String
    let type = "email"
}

private struct RefreshSessionRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct VerifyOTPResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: SupabaseUserResponse

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

private struct SupabaseUserResponse: Decodable {
    let id: String?
    let email: String?
}

private struct SupabaseErrorResponse: Decodable {
    let message: String?
}
