import Foundation

enum SupabaseAuthServiceError: LocalizedError {
    case missingConfiguration
    case missingEmail
    case missingPassword
    case weakPassword(minimumLength: Int)
    case invalidCredentials(message: String)
    case emailNotConfirmed
    case unauthorized(message: String)
    case retryable(message: String)
    case invalidResponse
    case sessionMissingAfterLogin
    case invalidRequestPayload

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase Auth configuration is missing. Set ONEDONE_SUPABASE_URL and ONEDONE_SUPABASE_ANON_KEY."
        case .missingEmail:
            return "Enter your email to continue."
        case .missingPassword:
            return "Enter your password to continue."
        case let .weakPassword(minimumLength):
            return "Password must be at least \(minimumLength) characters."
        case let .invalidCredentials(message):
            return message
        case .emailNotConfirmed:
            return "Your email is not confirmed yet. Check your inbox and confirm your account."
        case let .unauthorized(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Unexpected auth response. Please try again."
        case .sessionMissingAfterLogin:
            return "Could not start your session after login. Please try again."
        case .invalidRequestPayload:
            return "Could not prepare auth request. Please try again."
        }
    }
}

protocol SupabaseAuthServiceProtocol {
    func signUp(email: String, password: String) async throws -> AuthSignUpResult
    func logIn(email: String, password: String) async throws -> StoredAuthSession
    func refreshSession(refreshToken: String) async throws -> StoredAuthSession
    func logOut(accessToken: String?) async
}

struct SupabaseAuthService: SupabaseAuthServiceProtocol {
    private static let minimumPasswordLength = 6

    let environment: APIEnvironment
    let urlSession: URLSession

    init(environment: APIEnvironment = .current, urlSession: URLSession = .shared) {
        self.environment = environment
        self.urlSession = urlSession
    }

    func signUp(email: String, password: String) async throws -> AuthSignUpResult {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try validateCredentials(email: normalizedEmail, password: password)

        struct RequestBody: Encodable {
            let email: String
            let password: String
        }

        let data = try await requestJSON(
            path: "signup",
            method: "POST",
            body: RequestBody(email: normalizedEmail, password: password)
        )

        guard let decoded = try? JSONDecoder().decode(SupabaseAuthSignUpResponseDTO.self, from: data) else {
            throw SupabaseAuthServiceError.invalidResponse
        }

        if let sessionDTO = decoded.session {
            return .authenticated(StoredAuthSession.from(dto: sessionDTO))
        }

        return .requiresEmailConfirmation(email: normalizedEmail)
    }

    func logIn(email: String, password: String) async throws -> StoredAuthSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try validateCredentials(email: normalizedEmail, password: password)

        struct RequestBody: Encodable {
            let email: String
            let password: String
        }

        let data = try await requestJSON(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            method: "POST",
            body: RequestBody(email: normalizedEmail, password: password)
        )

        guard let dto = try? JSONDecoder().decode(SupabaseAuthSessionDTO.self, from: data) else {
            throw SupabaseAuthServiceError.sessionMissingAfterLogin
        }

        return StoredAuthSession.from(dto: dto)
    }

    func refreshSession(refreshToken: String) async throws -> StoredAuthSession {
        guard !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SupabaseAuthServiceError.invalidRequestPayload
        }

        struct RequestBody: Encodable {
            let refreshToken: String

            enum CodingKeys: String, CodingKey {
                case refreshToken = "refresh_token"
            }
        }

        let data = try await requestJSON(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            method: "POST",
            body: RequestBody(refreshToken: refreshToken)
        )

        guard let dto = try? JSONDecoder().decode(SupabaseAuthSessionDTO.self, from: data) else {
            throw SupabaseAuthServiceError.invalidResponse
        }

        return StoredAuthSession.from(dto: dto)
    }

    func logOut(accessToken: String?) async {
        guard let supabaseURL = environment.supabaseURL,
              let anonKey = environment.supabaseAnonKey else { return }

        guard let url = URL(string: "auth/v1/logout", relativeTo: supabaseURL)?.absoluteURL else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }

        _ = try? await urlSession.data(for: request)
    }

    private func requestJSON<T: Encodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: T
    ) async throws -> Data {
        let (supabaseURL, anonKey) = try requireConfig()
        let baseURL = try authURL(base: supabaseURL, path: path)

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw SupabaseAuthServiceError.invalidRequestPayload
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let encodedBody = try JSONEncoder().encode(body)
        try validateRequestBody(encodedBody)
        request.httpBody = encodedBody

        return try await perform(request: request)
    }

    private func perform(request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseAuthServiceError.invalidResponse
            }

            if (200...299).contains(httpResponse.statusCode) {
                return data
            }

            let mappedError = mapAuthError(
                statusCode: httpResponse.statusCode,
                rawMessage: decodeErrorMessage(data)
            )

            throw mappedError
        } catch let error as SupabaseAuthServiceError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw SupabaseAuthServiceError.retryable(message: "You appear to be offline. Please connect and try again.")
            case .timedOut:
                throw SupabaseAuthServiceError.retryable(message: "Auth request timed out. Please try again.")
            default:
                throw SupabaseAuthServiceError.retryable(message: "Network issue while contacting Supabase Auth.")
            }
        } catch {
            throw SupabaseAuthServiceError.retryable(message: "Auth request failed. Please try again.")
        }
    }

    private func validateCredentials(email: String, password: String) throws {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SupabaseAuthServiceError.missingEmail
        }

        if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SupabaseAuthServiceError.missingPassword
        }

        if password.count < Self.minimumPasswordLength {
            throw SupabaseAuthServiceError.weakPassword(minimumLength: Self.minimumPasswordLength)
        }
    }

    private func validateRequestBody(_ body: Data) throws {
        guard !body.isEmpty else {
            throw SupabaseAuthServiceError.invalidRequestPayload
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: body),
           let dictionary = jsonObject as? [String: Any],
           dictionary.isEmpty {
            throw SupabaseAuthServiceError.invalidRequestPayload
        }
    }

    private func decodeErrorMessage(_ data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(SupabaseAuthErrorDTO.self, from: data) {
            return decoded.message ?? decoded.errorDescription ?? decoded.msg ?? decoded.error
        }
        return nil
    }

    private func requireConfig() throws -> (URL, String) {
        guard let supabaseURL = environment.supabaseURL,
              let anonKey = environment.supabaseAnonKey else {
            throw SupabaseAuthServiceError.missingConfiguration
        }
        return (supabaseURL, anonKey)
    }

    private func mapAuthError(statusCode: Int, rawMessage: String?) -> SupabaseAuthServiceError {
        let normalized = (rawMessage ?? "").lowercased()

        if normalized.contains("email not confirmed") {
            return .emailNotConfirmed
        }

        if normalized.contains("could not parse request body as json") ||
            normalized.contains("unexpected end of json input") {
            return .retryable(message: "Could not process login request right now. Please try again.")
        }

        if normalized.contains("invalid login credentials") ||
            normalized.contains("invalid_grant") ||
            normalized.contains("invalid credentials") {
            return .invalidCredentials(message: "Email or password is incorrect.")
        }

        if normalized.contains("email") && normalized.contains("required") {
            return .missingEmail
        }

        if normalized.contains("password") && normalized.contains("required") {
            return .missingPassword
        }

        switch statusCode {
        case 400, 401:
            return .invalidCredentials(message: "Email or password is incorrect.")
        case 403:
            return .unauthorized(message: "This account cannot log in right now. Please try again.")
        case 408, 409, 425, 429:
            return .retryable(message: "Auth service is temporarily unavailable. Please try again.")
        default:
            if statusCode >= 500 {
                return .retryable(message: "Auth service is temporarily unavailable. Please try again.")
            }
            return .retryable(message: "Could not complete authentication right now. Please try again.")
        }
    }

    private func authURL(base: URL, path: String) throws -> URL {
        guard let url = URL(string: "auth/v1/\(path)", relativeTo: base)?.absoluteURL else {
            throw SupabaseAuthServiceError.invalidResponse
        }
        return url
    }
}

struct MockSupabaseAuthService: SupabaseAuthServiceProtocol {
    func signUp(email: String, password: String) async throws -> AuthSignUpResult {
        .authenticated(
            StoredAuthSession(
                accessToken: "mock-access-token",
                refreshToken: "mock-refresh-token",
                tokenType: "bearer",
                expiresAt: Date().addingTimeInterval(3600),
                userID: UUID().uuidString,
                userEmail: email
            )
        )
    }

    func logIn(email: String, password: String) async throws -> StoredAuthSession {
        StoredAuthSession(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            tokenType: "bearer",
            expiresAt: Date().addingTimeInterval(3600),
            userID: UUID().uuidString,
            userEmail: email
        )
    }

    func refreshSession(refreshToken: String) async throws -> StoredAuthSession {
        StoredAuthSession(
            accessToken: "mock-access-token-refreshed",
            refreshToken: refreshToken,
            tokenType: "bearer",
            expiresAt: Date().addingTimeInterval(3600),
            userID: UUID().uuidString,
            userEmail: "mock@onedone.dev"
        )
    }

    func logOut(accessToken: String?) async {}
}
