import Foundation

protocol AuthTokenProvider {
    func accessToken() -> String?
}

struct NoAuthTokenProvider: AuthTokenProvider {
    func accessToken() -> String? {
        nil
    }
}
