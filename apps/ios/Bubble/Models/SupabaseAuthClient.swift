import Foundation
import Security

struct SupabaseAuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let userID: String
    let email: String
}

enum SupabaseAuthError: LocalizedError {
    case missingConfiguration
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Missing Supabase configuration."
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

    func sendMagicCode(email: String) async throws {
        var request = try authRequest(path: "otp")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(OTPRequest(email: email))

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
            userID: userID,
            email: response.user.email ?? email
        )
        try saveSession(session)
        return session
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

private struct OTPRequest: Encodable {
    let email: String
    let createUser = true

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
