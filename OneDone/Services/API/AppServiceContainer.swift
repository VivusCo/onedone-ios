import Foundation

enum ServiceScaffoldError: LocalizedError {
    case notImplemented(service: String, method: String)

    var errorDescription: String? {
        switch self {
        case let .notImplemented(service, method):
            return "\(service).\(method) is not implemented yet. Use mock services for runtime."
        }
    }
}

enum ServiceRuntimeMode {
    case mock
    case remoteAccessState
    case remotePlaceholder
}

struct AppServiceContainer {
    var runtimeMode: ServiceRuntimeMode
    var accessStateService: any AccessStateServiceProtocol
    var taskService: any TaskServiceProtocol
    var reminderService: any ReminderServiceProtocol
    var subscriptionService: any SubscriptionServiceProtocol

    static let mock = AppServiceContainer(
        runtimeMode: .mock,
        accessStateService: MockAccessStateService(),
        taskService: MockTaskService(),
        reminderService: MockReminderService(),
        subscriptionService: MockSubscriptionService()
    )

    static func remoteAccessState(
        environment: APIEnvironment,
        tokenProvider: any AuthTokenProvider = NoAuthTokenProvider()
    ) -> AppServiceContainer {
        AppServiceContainer(
            runtimeMode: .remoteAccessState,
            accessStateService: RemoteAccessStateService(
                environment: environment,
                tokenProvider: tokenProvider
            ),
            taskService: MockTaskService(),
            reminderService: MockReminderService(),
            subscriptionService: MockSubscriptionService()
        )
    }

    static let remotePlaceholder = AppServiceContainer(
        runtimeMode: .remotePlaceholder,
        accessStateService: RemoteAccessStateService(),
        taskService: RemoteTaskService(),
        reminderService: RemoteReminderService(),
        subscriptionService: RemoteSubscriptionService()
    )
}
