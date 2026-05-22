import Foundation

struct MockAccessStateService: AccessStateServiceProtocol {
    func completeOnboarding(_ request: CompleteOnboardingRequest) async throws -> AccessStateSnapshot {
        AccessStateSnapshot(state: .starter_active, starterDaysRemaining: 3)
    }

    func getAccessState() async throws -> AccessStateSnapshot {
        AccessStateSnapshot(state: .starter_active, starterDaysRemaining: 3)
    }
}
