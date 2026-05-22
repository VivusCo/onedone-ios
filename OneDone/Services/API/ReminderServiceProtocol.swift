import Foundation

enum ReminderSyncServiceError: LocalizedError {
    case remoteSyncDisabled
    case missingBaseURL
    case accessDenied(message: String)
    case retryable(message: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .remoteSyncDisabled:
            return "Remote reminder sync is disabled."
        case .missingBaseURL:
            return "OneDone API base URL is missing. Configure ONEDONE_API_BASE_URL to enable reminder sync."
        case let .accessDenied(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Could not understand backend reminder response."
        }
    }
}

protocol ReminderServiceProtocol {
    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult
    func cancelReminder(identifier: String)
    func syncReminderCreate(_ request: ReminderCreateRequest) async throws -> ReminderSyncResponse
    func syncReminderUpdate(_ request: ReminderUpdateRequest) async throws -> ReminderSyncResponse
    func syncReminderCancel(_ request: ReminderCancelRequest) async throws -> ReminderSyncResponse
    func syncReminderSnooze(_ request: ReminderSnoozeRequest) async throws -> ReminderSyncResponse
    func fetchReminders(taskID: String) async throws -> [BackendReminderDTO]
}
