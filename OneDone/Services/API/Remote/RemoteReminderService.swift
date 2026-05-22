import Foundation

struct RemoteReminderService: ReminderServiceProtocol {
    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult {
        .failed
    }

    func cancelReminder(identifier: String) {
        // TODO: implement remote reminder cancellation when backend reminders are enabled.
    }
}
