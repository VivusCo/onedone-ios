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

        let data = try await get(
            endpoint: "get-reminders",
            queryItems: [URLQueryItem(name: "task_id", value: taskID)]
        )

        if let reminders = decodeArrayWrapper(data, as: BackendReminderDTO.self) {
            return reminders
        }

        if let reminders = decodeArrayByKeys(data, keys: ["reminders", "items", "data"], as: BackendReminderDTO.self) {
            return reminders
        }

        if let singleReminder = decodeSingleWrapper(data, as: BackendReminderDTO.self) {
            return [singleReminder]
        }

        logReadDecodeFailure(endpoint: "get-reminders", data: data)
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

    private func get(endpoint: String, queryItems: [URLQueryItem]) async throws -> Data {
        guard let url = edgeFunctionURL(endpoint: endpoint, queryItems: queryItems) else {
            throw ReminderSyncServiceError.missingBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenProvider.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReminderSyncServiceError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 402 || httpResponse.statusCode == 403 {
                logReadHTTPFailure(endpoint: endpoint, statusCode: httpResponse.statusCode, data: data)
                let message = decodeErrorMessage(data) ?? "Access denied for reminders."
                throw ReminderSyncServiceError.accessDenied(message: message)
            }

            if httpResponse.statusCode == 408 || httpResponse.statusCode == 409 || httpResponse.statusCode == 425 ||
                httpResponse.statusCode == 429 || httpResponse.statusCode >= 500 {
                logReadHTTPFailure(endpoint: endpoint, statusCode: httpResponse.statusCode, data: data)
                let message = decodeErrorMessage(data) ?? "Could not load reminders right now."
                throw ReminderSyncServiceError.retryable(message: message)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                logReadHTTPFailure(endpoint: endpoint, statusCode: httpResponse.statusCode, data: data)
                let message = decodeErrorMessage(data) ?? "Reminder request failed."
                throw ReminderSyncServiceError.retryable(message: message)
            }

            return data
        } catch let error as ReminderSyncServiceError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw ReminderSyncServiceError.retryable(message: "You appear to be offline. Reminder data is unavailable.")
            case .timedOut:
                throw ReminderSyncServiceError.retryable(message: "Reminder request timed out. Please try again.")
            default:
                throw ReminderSyncServiceError.retryable(message: "Network issue while loading reminders.")
            }
        } catch {
            throw ReminderSyncServiceError.retryable(message: "Could not load reminders right now.")
        }
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
        struct NestedErrorPayload: Decodable {
            struct NestedError: Decodable {
                let code: String?
                let message: String?
                let retryable: Bool?
            }

            let ok: Bool?
            let error: NestedError?
            let message: String?
        }

        struct FlatErrorPayload: Decodable {
            let message: String?
            let error: String?
            let errorMessage: String?
            let detail: String?

            enum CodingKeys: String, CodingKey {
                case message
                case error
                case errorMessage = "error_message"
                case detail
            }
        }

        if let payload = try? JSONDecoder().decode(NestedErrorPayload.self, from: data),
           let nestedMessage = payload.error?.message,
           !nestedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nestedMessage
        }

        if let payload = try? JSONDecoder().decode(FlatErrorPayload.self, from: data) {
            return payload.message ?? payload.errorMessage ?? payload.detail ?? payload.error
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

    private func decodeArrayByKeys<T: Decodable>(_ data: Data, keys: [String], as type: T.Type) -> [T]? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return nil
        }

        for key in keys {
            guard let nested = dictionary[key],
                  JSONSerialization.isValidJSONObject(nested),
                  let nestedData = try? JSONSerialization.data(withJSONObject: nested) else {
                continue
            }

            if let decoded = decodeArrayWrapper(nestedData, as: type) {
                return decoded
            }
        }

        return nil
    }

    private func edgeFunctionURL(endpoint: String, queryItems: [URLQueryItem]) -> URL? {
        guard let baseURL = environment.baseURL else { return nil }

        let cleanedEndpoint = sanitizeEndpoint(endpoint)
        let basePath = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()

        let functionBaseURL: URL
        if basePath.hasSuffix("functions/v1") {
            functionBaseURL = baseURL
        } else {
            functionBaseURL = baseURL
                .appendingPathComponent("functions")
                .appendingPathComponent("v1")
        }

        var components = URLComponents(url: functionBaseURL.appendingPathComponent(cleanedEndpoint), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    private func sanitizeEndpoint(_ endpoint: String) -> String {
        var cleaned = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.hasPrefix("/") {
            cleaned.removeFirst()
        }
        if cleaned.lowercased().hasPrefix("functions/v1/") {
            cleaned.removeFirst("functions/v1/".count)
        }
        return cleaned
    }

    private func logReadHTTPFailure(endpoint: String, statusCode: Int, data: Data) {
#if DEBUG
        let keys = topLevelJSONKeys(from: data)
        let keysDescription = keys.isEmpty ? "none" : keys.joined(separator: ",")
        print("[OneDone][RemoteRead] endpoint=\(endpoint) status=\(statusCode) keys=\(keysDescription)")
#endif
    }

    private func logReadDecodeFailure(endpoint: String, data: Data) {
#if DEBUG
        let keys = topLevelJSONKeys(from: data)
        let keysDescription = keys.isEmpty ? "none" : keys.joined(separator: ",")
        print("[OneDone][RemoteReadDecode] endpoint=\(endpoint) keys=\(keysDescription)")
#endif
    }

    private func topLevelJSONKeys(from data: Data) -> [String] {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return []
        }
        return dictionary.keys.sorted()
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
