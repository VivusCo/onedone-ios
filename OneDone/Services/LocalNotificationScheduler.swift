import Foundation
import UserNotifications

enum LocalReminderScheduleResult {
    case scheduled(identifier: String)
    case permissionDenied
    case failed
}

final class LocalNotificationScheduler {
    static let shared = LocalNotificationScheduler()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult {
        let status = await authorizationStatus()

        var effectiveStatus = status
        if status == .notDetermined {
            do {
                let granted = try await requestAuthorizationIfNeeded()
                effectiveStatus = granted ? .authorized : .denied
            } catch {
                return .failed
            }
        }

        guard isAuthorizationAllowed(effectiveStatus) else {
            return .permissionDenied
        }

        let identifier = "onedone.reminder.\(UUID().uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "OneDone reminder"
        content.body = "Check task: \(taskTitle)"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await addRequest(request)
            return .scheduled(identifier: identifier)
        } catch {
            return .failed
        }
    }

    func cancelReminder(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }

    private func isAuthorizationAllowed(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func requestAuthorizationIfNeeded() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func addRequest(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
