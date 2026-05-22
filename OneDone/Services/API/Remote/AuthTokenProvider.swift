import Foundation

protocol AuthTokenProvider {
    func accessToken() -> String?
}

struct NoAuthTokenProvider: AuthTokenProvider {
    func accessToken() -> String? {
        nil
    }
}

struct EnvironmentAuthTokenProvider: AuthTokenProvider {
    static let authTokenKey = "ONEDONE_AUTH_TOKEN"

    func accessToken() -> String? {
        let envValue = ProcessInfo.processInfo.environment[Self.authTokenKey]
        let plistValue = Bundle.main.object(forInfoDictionaryKey: Self.authTokenKey) as? String
        let rawToken = envValue ?? plistValue

        guard let rawToken else { return nil }
        let trimmed = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
