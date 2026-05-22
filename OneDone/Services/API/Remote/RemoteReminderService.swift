import Foundation

struct RemoteReminderService: ReminderServiceProtocol {
    let environment: APIEnvironment
    let tokenProvider: any AuthTokenProvider
    let urlSession: URLSession

    init(
        environment: APIEnvironment = .current,
        tokenProvider: any AuthTokenProvider = NoAuthTokenProvider(),
        urlSession: URLSession = .shared
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.urlSession = urlSession
    }

    func scheduleReminder(taskTitle: String, date: Date) async -> LocalReminderScheduleResult {
        await LocalNotificationScheduler.shared.scheduleReminder(taskTitle: taskTitle, date: date)
    }

    func cancelReminder(identifier: String) {
        LocalNotificationScheduler.shared.cancelReminder(identifier: identifier)
    }

    func syncReminderCreate(_ request: ReminderCreateRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            path: "functions/v1/reminder-create",
            body: request
        )
    }

    func syncReminderUpdate(_ request: ReminderUpdateRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            path: "functions/v1/reminder-update",
            body: request
        )
    }

    func syncReminderCancel(_ request: ReminderCancelRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            path: "functions/v1/reminder-cancel",
            body: request
        )
    }

    func syncReminderSnooze(_ request: ReminderSnoozeRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            path: "functions/v1/reminder-snooze",
            body: request
        )
    }

    func fetchReminders(taskID: String) async throws -> [BackendReminderDTO] {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        struct RequestBody: Codable {
            let taskID: String

            enum CodingKeys: String, CodingKey {
                case taskID = "task_id"
            }
        }

        let data = try await post(
            path: "functions/v1/get-reminders",
            body: RequestBody(taskID: taskID)
        )

        if let reminders = decodeArrayWrapper(data, as: BackendReminderDTO.self) {
            return reminders
        }

        if let singleReminder = decodeSingleWrapper(data, as: BackendReminderDTO.self) {
            return [singleReminder]
        }

        return []
    }

    private func postReminderAction<T: Codable>(
        path: String,
        body: T
    ) async throws -> ReminderSyncResponse {
        let data = try await post(path: path, body: body)

        if let response = decodeSingleWrapper(data, as: ReminderSyncResponse.self) {
            return response
        }

        throw ReminderSyncServiceError.invalidResponse
    }

    private func post<T: Codable>(path: String, body: T) async throws -> Data {
        guard let baseURL = environment.baseURL else {
            throw ReminderSyncServiceError.missingBaseURL
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenProvider.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReminderSyncServiceError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 402 || httpResponse.statusCode == 403 {
                let message = decodeErrorMessage(data) ?? "Access denied for reminder action."
                throw ReminderSyncServiceError.accessDenied(message: message)
            }

            if httpResponse.statusCode == 408 || httpResponse.statusCode == 409 || httpResponse.statusCode == 425 ||
                httpResponse.statusCode == 429 || httpResponse.statusCode >= 500 {
                let message = decodeErrorMessage(data) ?? "Reminder action failed. Please try again."
                throw ReminderSyncServiceError.retryable(message: message)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = decodeErrorMessage(data) ?? "Reminder action failed."
                throw ReminderSyncServiceError.retryable(message: message)
            }

            return data
        } catch let error as ReminderSyncServiceError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw ReminderSyncServiceError.retryable(message: "You appear to be offline. Reminder is local-only for now.")
            case .timedOut:
                throw ReminderSyncServiceError.retryable(message: "Reminder sync timed out. Please try again.")
            default:
                throw ReminderSyncServiceError.retryable(message: "Network issue while syncing reminder.")
            }
        } catch {
            throw ReminderSyncServiceError.retryable(message: "Reminder action failed. Please try again.")
        }
    }

    private func decodeErrorMessage(_ data: Data) -> String? {
        struct ErrorPayload: Decodable {
            let message: String?
            let error: String?
        }

        if let payload = try? JSONDecoder().decode(ErrorPayload.self, from: data) {
            return payload.message ?? payload.error
        }
        return nil
    }

    private func decodeSingleWrapper<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
        if let direct = try? JSONDecoder().decode(T.self, from: data) {
            return direct
        }

        if let wrapped = try? JSONDecoder().decode(ReminderResponseWrapper<T>.self, from: data) {
            return wrapped.data ?? wrapped.result ?? wrapped.response
        }

        return nil
    }

    private func decodeArrayWrapper<T: Decodable>(_ data: Data, as type: T.Type) -> [T]? {
        if let direct = try? JSONDecoder().decode([T].self, from: data) {
            return direct
        }

        if let wrapped = try? JSONDecoder().decode(ReminderArrayResponseWrapper<T>.self, from: data) {
            return wrapped.data ?? wrapped.result ?? wrapped.response
        }

        return nil
    }
}

private struct ReminderResponseWrapper<T: Decodable>: Decodable {
    let data: T?
    let result: T?
    let response: T?
}

private struct ReminderArrayResponseWrapper<T: Decodable>: Decodable {
    let data: [T]?
    let result: [T]?
    let response: [T]?
}
