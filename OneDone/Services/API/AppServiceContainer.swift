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

struct AppServiceContainer {
    var accessStateService: any AccessStateServiceProtocol
    var taskService: any TaskServiceProtocol
    var reminderService: any ReminderServiceProtocol
    var subscriptionService: any SubscriptionServiceProtocol

    static let mock = AppServiceContainer(
        accessStateService: MockAccessStateService(),
        taskService: MockTaskService(),
        reminderService: MockReminderService(),
        subscriptionService: MockSubscriptionService()
    )

    static let remotePlaceholder = AppServiceContainer(
        accessStateService: RemoteAccessStateService(),
        taskService: RemoteTaskService(),
        reminderService: RemoteReminderService(),
        subscriptionService: RemoteSubscriptionService()
    )
}
