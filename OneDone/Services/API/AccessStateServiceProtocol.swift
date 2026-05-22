import Foundation

struct AccessStateSnapshot {
    var state: APIAccessState
    var starterDaysRemaining: Int?
    var statusNote: String?
}

protocol AccessStateServiceProtocol {
    func completeOnboarding(_ request: CompleteOnboardingRequest) async throws -> AccessStateSnapshot
    func getAccessState() async throws -> AccessStateSnapshot
}
