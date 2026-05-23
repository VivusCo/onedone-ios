import Foundation

enum SubscriptionServiceError: LocalizedError {
    case remoteSubscriptionDisabled
    case missingFunctionsBaseURL
    case missingProductConfiguration
    case productUnavailable
    case authenticationRequired
    case purchasePending
    case unverifiedTransaction
    case backendValidationFailed(message: String)
    case backendRestoreFailed(message: String)
    case retryable(message: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .remoteSubscriptionDisabled:
            return "Subscription purchase is disabled in this runtime mode."
        case .missingFunctionsBaseURL:
            return "Backend configuration is missing. Set ONEDONE_FUNCTIONS_BASE_URL."
        case .missingProductConfiguration:
            return "Subscription product is not configured. Set ONEDONE_SUBSCRIPTION_PRODUCT_ID."
        case .productUnavailable:
            return "Subscription product is unavailable right now. Please try again later."
        case .authenticationRequired:
            return "Your session expired. Please log in again."
        case .purchasePending:
            return "Purchase is pending approval. Please check again shortly."
        case .unverifiedTransaction:
            return "Could not verify App Store transaction."
        case let .backendValidationFailed(message):
            return message
        case let .backendRestoreFailed(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Unexpected subscription response. Please try again."
        }
    }
}

enum SubscriptionPurchaseResult {
    case purchased(ValidateSubscriptionResponse)
    case cancelled
    case pending
}

struct SubscriptionRestoreResult {
    var response: RestorePurchasesResponse
    var restoredEntitlementCount: Int
}

protocol SubscriptionServiceProtocol {
    func startSubscriptionPurchase() async throws -> SubscriptionPurchaseResult
    func restorePurchases() async throws -> SubscriptionRestoreResult
}
