import Foundation

struct AccessStateSnapshot {
    var state: APIAccessState
    var starterDaysRemaining: Int?
}

protocol AccessStateServiceProtocol {
    func completeOnboarding(_ request: CompleteOnboardingRequest) throws -> AccessStateSnapshot
    func getAccessState() throws -> AccessStateSnapshot
}
