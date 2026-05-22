import Foundation

struct SupabaseAuthUserDTO: Decodable {
    let id: String?
    let email: String?
}

struct SupabaseAuthSessionDTO: Decodable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String?
    let expiresIn: Int?
    let expiresAtUnix: Int?
    let user: SupabaseAuthUserDTO?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAtUnix = "expires_at"
        case user
    }
}

struct SupabaseAuthSignUpResponseDTO: Decodable {
    let user: SupabaseAuthUserDTO?
    let session: SupabaseAuthSessionDTO?
}

struct SupabaseAuthErrorDTO: Decodable {
    let error: String?
    let errorDescription: String?
    let message: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
        case msg
    }
}

struct StoredAuthSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String?
    let expiresAt: Date?
    let userID: String?
    let userEmail: String?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }

    var isExpiringSoon: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date().addingTimeInterval(120)
    }

    static func from(dto: SupabaseAuthSessionDTO) -> StoredAuthSession {
        let resolvedExpiry: Date?
        if let expiresAtUnix = dto.expiresAtUnix {
            resolvedExpiry = Date(timeIntervalSince1970: TimeInterval(expiresAtUnix))
        } else if let expiresIn = dto.expiresIn {
            resolvedExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            resolvedExpiry = nil
        }

        return StoredAuthSession(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            tokenType: dto.tokenType,
            expiresAt: resolvedExpiry,
            userID: dto.user?.id,
            userEmail: dto.user?.email
        )
    }
}

enum AuthSignUpResult {
    case authenticated(StoredAuthSession)
    case requiresEmailConfirmation(email: String)
}
