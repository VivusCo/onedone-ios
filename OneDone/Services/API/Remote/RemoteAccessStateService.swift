import Foundation

struct RemoteAccessStateService: AccessStateServiceProtocol {
    func completeOnboarding(_ request: CompleteOnboardingRequest) throws -> AccessStateSnapshot {
        throw ServiceScaffoldError.notImplemented(service: "RemoteAccessStateService", method: "completeOnboarding")
    }

    func getAccessState() throws -> AccessStateSnapshot {
        throw ServiceScaffoldError.notImplemented(service: "RemoteAccessStateService", method: "getAccessState")
    }
}
