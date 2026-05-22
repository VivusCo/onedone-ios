import Foundation

struct MockAccessStateService: AccessStateServiceProtocol {
    func completeOnboarding(_ request: CompleteOnboardingRequest) throws -> AccessStateSnapshot {
        AccessStateSnapshot(state: .starter_active, starterDaysRemaining: 3)
    }

    func getAccessState() throws -> AccessStateSnapshot {
        AccessStateSnapshot(state: .starter_active, starterDaysRemaining: 3)
    }
}
