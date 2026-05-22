import Foundation

struct MockReminderService: ReminderServiceProtocol {
    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult {
        await LocalNotificationScheduler.shared.scheduleReminder(taskTitle: taskTitle, date: date)
    }

    func cancelReminder(identifier: String) {
        LocalNotificationScheduler.shared.cancelReminder(identifier: identifier)
    }
}
