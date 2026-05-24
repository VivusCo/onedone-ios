import Foundation

struct MockSubscriptionService: SubscriptionServiceProtocol {
    func startSubscriptionPurchase() async throws -> SubscriptionPurchaseResult {
        .purchased(
            ValidateSubscriptionResponse(
                access: APIAccessStatePayload(accessState: .trial_active, starterDaysRemaining: 0)
            )
        )
    }

    func restorePurchases() async throws -> SubscriptionRestoreResult {
        SubscriptionRestoreResult(
            response: RestorePurchasesResponse(
                access: APIAccessStatePayload(accessState: .subscription_active, starterDaysRemaining: 0)
            ),
            restoredEntitlementCount: 1
        )
    }
}
