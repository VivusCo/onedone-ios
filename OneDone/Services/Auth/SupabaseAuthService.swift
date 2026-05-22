import Foundation

enum SupabaseAuthServiceError: LocalizedError {
    case missingConfiguration
    case invalidCredentials(message: String)
    case unauthorized(message: String)
    case retryable(message: String)
    case invalidResponse
    case sessionMissingAfterLogin

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase Auth configuration is missing. Set ONEDONE_SUPABASE_URL and ONEDONE_SUPABASE_ANON_KEY."
        case let .invalidCredentials(message):
            return message
        case let .unauthorized(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Could not understand Supabase Auth response."
        case .sessionMissingAfterLogin:
            return "Login succeeded but no session was returned."
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
    let environment: APIEnvironment
    let urlSession: URLSession

    init(environment: APIEnvironment = .current, urlSession: URLSession = .shared) {
        self.environment = environment
        self.urlSession = urlSession
    }

    func signUp(email: String, password: String) async throws -> AuthSignUpResult {
        struct RequestBody: Encodable {
            let email: String
            let password: String
        }

        let data = try await requestJSON(
            path: "signup",
            method: "POST",
            body: RequestBody(email: email, password: password)
        )

        guard let decoded = try? JSONDecoder().decode(SupabaseAuthSignUpResponseDTO.self, from: data) else {
            throw SupabaseAuthServiceError.invalidResponse
        }

        if let sessionDTO = decoded.session {
            return .authenticated(StoredAuthSession.from(dto: sessionDTO))
        }

        return .requiresEmailConfirmation(email: email)
    }

    func logIn(email: String, password: String) async throws -> StoredAuthSession {
        let formValues = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "password", value: password)
        ]

        let data = try await requestForm(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            method: "POST",
            formValues: formValues
        )

        guard let dto = try? JSONDecoder().decode(SupabaseAuthSessionDTO.self, from: data) else {
            throw SupabaseAuthServiceError.sessionMissingAfterLogin
        }

        return StoredAuthSession.from(dto: dto)
    }

    func refreshSession(refreshToken: String) async throws -> StoredAuthSession {
        let formValues = [
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]

        let data = try await requestForm(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            method: "POST",
            formValues: formValues
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
        method: String,
        body: T
    ) async throws -> Data {
        let (supabaseURL, anonKey) = try requireConfig()
        let url = try authURL(base: supabaseURL, path: path)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        return try await perform(request: request)
    }

    private func requestForm(
        path: String,
        queryItems: [URLQueryItem],
        method: String,
        formValues: [URLQueryItem]
    ) async throws -> Data {
        let (supabaseURL, anonKey) = try requireConfig()
        let baseURL = try authURL(base: supabaseURL, path: path)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw SupabaseAuthServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        var formComponents = URLComponents()
        formComponents.queryItems = formValues
        request.httpBody = formComponents.percentEncodedQuery?.data(using: .utf8)

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

            let message = decodeErrorMessage(data) ?? "Auth request failed. Please try again."

            switch httpResponse.statusCode {
            case 400, 401:
                throw SupabaseAuthServiceError.invalidCredentials(message: message)
            case 403:
                throw SupabaseAuthServiceError.unauthorized(message: message)
            case 408, 409, 425, 429:
                throw SupabaseAuthServiceError.retryable(message: message)
            default:
                if httpResponse.statusCode >= 500 {
                    throw SupabaseAuthServiceError.retryable(message: message)
                }
                throw SupabaseAuthServiceError.retryable(message: message)
            }
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
