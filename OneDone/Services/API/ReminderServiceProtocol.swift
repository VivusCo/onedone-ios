import Foundation

protocol ReminderServiceProtocol {
    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult
    func cancelReminder(identifier: String)
}
