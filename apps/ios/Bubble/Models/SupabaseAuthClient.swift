import Foundation

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

    private let sessionKey = "rinkler.supabase.auth.session"
    private let baseURL: URL
    private let anonKey: String
    private let urlSession: URLSession
    private let userDefaults: UserDefaults

    init(
        urlSession: URLSession = .shared,
        userDefaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) {
        guard let urlString = bundle.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: urlString),
              let key = bundle.infoDictionary?["SUPABASE_KEY"] as? String,
              !key.isEmpty else {
            fatalError("Missing SUPABASE_URL or SUPABASE_KEY in Info.plist. Check Secrets.xcconfig.")
        }

        self.baseURL = url
        self.anonKey = key
        self.urlSession = urlSession
        self.userDefaults = userDefaults
    }

    func sendMagicCode(email: String) async throws {
        var request = authRequest(path: "otp")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(OTPRequest(email: email))

        try await send(request)
    }

    func verifyEmailOTP(email: String, token: String) async throws -> SupabaseAuthSession {
        var request = authRequest(path: "verify")
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
        saveSession(session)
        return session
    }

    func signOut() async {
        if let session = loadSession() {
            var request = authRequest(path: "logout")
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            _ = try? await urlSession.data(for: request)
        }

        clearSession()
    }

    func loadSession() -> SupabaseAuthSession? {
        guard let data = userDefaults.data(forKey: sessionKey) else {
            return nil
        }

        return try? JSONDecoder().decode(SupabaseAuthSession.self, from: data)
    }

    private func saveSession(_ session: SupabaseAuthSession) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

        userDefaults.set(data, forKey: sessionKey)
    }

    private func clearSession() {
        userDefaults.removeObject(forKey: sessionKey)
    }

    private func authRequest(path: String) -> URLRequest {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
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
