import Foundation

enum RemoteAccessStateServiceError: LocalizedError {
    case remoteAccessDisabled
    case missingBaseURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .remoteAccessDisabled:
            return "Remote access-state loading is disabled."
        case .missingBaseURL:
            return "OneDone API base URL is missing. Configure ONEDONE_API_BASE_URL to enable remote access-state loading."
        case .invalidResponse:
            return "Received an invalid response from the access-state endpoint."
        case let .httpStatus(status):
            return "Access-state request failed with status code \(status)."
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
        throw ServiceScaffoldError.notImplemented(service: "RemoteAccessStateService", method: "completeOnboarding")
    }

    func getAccessState() async throws -> AccessStateSnapshot {
        guard environment.useRemoteAccessState else {
            throw RemoteAccessStateServiceError.remoteAccessDisabled
        }

        guard let baseURL = environment.baseURL else {
            throw RemoteAccessStateServiceError.missingBaseURL
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("get-access-state"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenProvider.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteAccessStateServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RemoteAccessStateServiceError.httpStatus(httpResponse.statusCode)
        }

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
}
