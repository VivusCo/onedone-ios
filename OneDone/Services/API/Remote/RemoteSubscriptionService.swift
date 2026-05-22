import Foundation

struct RemoteSubscriptionService: SubscriptionServiceProtocol {
    func validateSubscription(_ request: ValidateSubscriptionRequest) throws -> ValidateSubscriptionResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteSubscriptionService", method: "validateSubscription")
    }

    func restorePurchases() throws -> RestorePurchasesResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteSubscriptionService", method: "restorePurchases")
    }
}
