import Foundation

struct MockSubscriptionService: SubscriptionServiceProtocol {
    func validateSubscription(_ request: ValidateSubscriptionRequest) throws -> ValidateSubscriptionResponse {
        ValidateSubscriptionResponse(
            access: APIAccessStatePayload(accessState: .trial_active, starterDaysRemaining: 0)
        )
    }

    func restorePurchases() throws -> RestorePurchasesResponse {
        RestorePurchasesResponse(
            access: APIAccessStatePayload(accessState: .subscription_active, starterDaysRemaining: 0)
        )
    }
}
