import Foundation

struct MockReminderService: ReminderServiceProtocol {
    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult {
        await LocalNotificationScheduler.shared.scheduleReminder(taskTitle: taskTitle, date: date)
    }

    func cancelReminder(identifier: String) {
        LocalNotificationScheduler.shared.cancelReminder(identifier: identifier)
    }

    func syncReminderCreate(_ request: ReminderCreateRequest) async throws -> ReminderSyncResponse {
        ReminderSyncResponse(
            taskID: request.taskID,
            reminderID: "mock-reminder-\(UUID().uuidString)",
            status: "active",
            message: "Mock reminder create synced."
        )
    }

    func syncReminderUpdate(_ request: ReminderUpdateRequest) async throws -> ReminderSyncResponse {
        ReminderSyncResponse(
            taskID: request.taskID,
            reminderID: request.reminderID,
            status: "active",
            message: "Mock reminder update synced."
        )
    }

    func syncReminderCancel(_ request: ReminderCancelRequest) async throws -> ReminderSyncResponse {
        ReminderSyncResponse(
            taskID: request.taskID,
            reminderID: request.reminderID,
            status: "canceled",
            message: "Mock reminder cancel synced."
        )
    }

    func syncReminderSnooze(_ request: ReminderSnoozeRequest) async throws -> ReminderSyncResponse {
        ReminderSyncResponse(
            taskID: request.taskID,
            reminderID: request.reminderID,
            status: "active",
            message: "Mock reminder snooze synced."
        )
    }

    func fetchReminders(taskID: String) async throws -> [BackendReminderDTO] {
        []
    }
}
