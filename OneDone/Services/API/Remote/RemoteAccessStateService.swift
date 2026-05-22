import Foundation

enum RemoteAccessStateServiceError: LocalizedError {
    case remoteAccessDisabled
    case missingBaseURL
    case unauthorized(message: String)
    case retryable(message: String)
    case invalidResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .remoteAccessDisabled:
            return "Remote access-state loading is disabled."
        case .missingBaseURL:
            return "OneDone functions base URL is missing. Configure ONEDONE_FUNCTIONS_BASE_URL to enable remote access-state loading."
        case let .unauthorized(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Received an invalid response from the access-state endpoint."
        case .decodingFailed:
            return "Could not decode access-state response from backend."
        }
    }
}

struct RemoteAccessStateService: AccessStateServiceProtocol {
    let environment: APIEnvironment
    let tokenProvider: any AuthTokenProvider
    let urlSession: URLSession

    init(
        environment: APIEnvironment = .current,
        tokenProvider: any AuthTokenProvider = NoAuthTokenProvider(),
        urlSession: URLSession = .shared
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.urlSession = urlSession
    }

    func completeOnboarding(_ request: CompleteOnboardingRequest) async throws -> AccessStateSnapshot {
        guard environment.useRemoteAccessState else {
            throw RemoteAccessStateServiceError.remoteAccessDisabled
        }

        let data = try await sendRequest(
            path: "complete-onboarding",
            method: "POST",
            body: request
        )

        let decoder = JSONDecoder()

        if let wrapped = try? decoder.decode(CompleteOnboardingResponse.self, from: data) {
            return AccessStateSnapshot(
                state: wrapped.access.accessState,
                starterDaysRemaining: wrapped.access.starterDaysRemaining,
                statusNote: wrapped.access.statusNote
            )
        }

        if let dto = try? decoder.decode(GetAccessStateDTO.self, from: data) {
            return AccessStateSnapshot(
                state: dto.access.accessState,
                starterDaysRemaining: dto.access.starterDaysRemaining,
                statusNote: dto.access.statusNote
            )
        }

        throw RemoteAccessStateServiceError.decodingFailed
    }

    func getAccessState() async throws -> AccessStateSnapshot {
        guard environment.useRemoteAccessState else {
            throw RemoteAccessStateServiceError.remoteAccessDisabled
        }

        let data = try await sendRequestWithoutBody(path: "get-access-state", method: "GET")

        let decoder = JSONDecoder()

        guard let decoded = try? decoder.decode(GetAccessStateDTO.self, from: data) else {
            throw RemoteAccessStateServiceError.decodingFailed
        }

        return AccessStateSnapshot(
            state: decoded.access.accessState,
            starterDaysRemaining: decoded.access.starterDaysRemaining,
            statusNote: decoded.access.statusNote
        )
    }

    private func sendRequest<T: Encodable>(
        path: String,
        method: String,
        body: T?
    ) async throws -> Data {
        guard let baseURL = environment.baseURL else {
            throw RemoteAccessStateServiceError.missingBaseURL
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = tokenProvider.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RemoteAccessStateServiceError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw RemoteAccessStateServiceError.unauthorized(
                    message: decodeErrorMessage(data) ?? "Your session is no longer valid. Please log in again."
                )
            }

            if httpResponse.statusCode == 408 || httpResponse.statusCode == 409 || httpResponse.statusCode == 425 ||
                httpResponse.statusCode == 429 || httpResponse.statusCode >= 500 {
                throw RemoteAccessStateServiceError.retryable(
                    message: decodeErrorMessage(data) ?? "Could not load access state right now. Please try again."
                )
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw RemoteAccessStateServiceError.retryable(
                    message: decodeErrorMessage(data) ?? "Access-state request failed. Please retry."
                )
            }

            return data
        } catch let error as RemoteAccessStateServiceError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw RemoteAccessStateServiceError.retryable(message: "You appear to be offline. Please connect and retry.")
            case .timedOut:
                throw RemoteAccessStateServiceError.retryable(message: "Request timed out. Please try again.")
            default:
                throw RemoteAccessStateServiceError.retryable(message: "Network issue while loading access state.")
            }
        } catch {
            throw RemoteAccessStateServiceError.retryable(message: "Could not load access state right now.")
        }
    }

    private func sendRequestWithoutBody(path: String, method: String) async throws -> Data {
        try await sendRequest(path: path, method: method, body: Optional<EmptyBody>.none)
    }

    private func decodeErrorMessage(_ data: Data) -> String? {
        struct ErrorPayload: Decodable {
            let error: String?
            let message: String?
        }

        guard let payload = try? JSONDecoder().decode(ErrorPayload.self, from: data) else {
            return nil
        }

        return payload.message ?? payload.error
    }
}

private struct EmptyBody: Encodable {}
