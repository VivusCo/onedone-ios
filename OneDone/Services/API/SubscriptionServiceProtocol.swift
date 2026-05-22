import Foundation

protocol SubscriptionServiceProtocol {
    func validateSubscription(_ request: ValidateSubscriptionRequest) throws -> ValidateSubscriptionResponse
    func restorePurchases() throws -> RestorePurchasesResponse
}
