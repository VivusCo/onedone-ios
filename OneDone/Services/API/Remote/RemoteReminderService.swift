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
            endpoint: "reminder-create",
            body: request
        )
    }

    func syncReminderUpdate(_ request: ReminderUpdateRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            endpoint: "reminder-update",
            body: request
        )
    }

    func syncReminderCancel(_ request: ReminderCancelRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            endpoint: "reminder-cancel",
            body: request
        )
    }

    func syncReminderSnooze(_ request: ReminderSnoozeRequest) async throws -> ReminderSyncResponse {
        guard environment.useRemoteReminderSync else {
            throw ReminderSyncServiceError.remoteSyncDisabled
        }

        return try await postReminderAction(
            endpoint: "reminder-snooze",
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

        if let embeddedError = classifyReadPayloadError(data) {
            throw embeddedError
        }

        logReadDecodeFailure(endpoint: "get-reminders", data: data)
        return []
    }

    private func postReminderAction<T: Codable>(
        endpoint: String,
        body: T
    ) async throws -> ReminderSyncResponse {
        let data = try await post(endpoint: endpoint, body: body)

        if let response = decodeSingleWrapper(data, as: ReminderSyncResponse.self) {
            return response
        }

        if let embeddedError = classifyActionPayloadError(data) {
            throw embeddedError
        }

        throw ReminderSyncServiceError.invalidResponse
    }

    private func get(endpoint: String, queryItems: [URLQueryItem]) async throws -> Data {
        guard let url = edgeFunctionURL(endpoint: endpoint, queryItems: queryItems) else {
#if DEBUG
            print("[OneDone][RemoteRead] endpoint=\(endpoint) stage=dispatch_skipped reason=missing_base_url")
#endif
            throw ReminderSyncServiceError.missingBaseURL
        }

        logReadDispatch(endpoint: endpoint, url: url, queryItems: queryItems)

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
            logReadResponseReceived(
                endpoint: endpoint,
                statusCode: httpResponse.statusCode,
                data: data
            )

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 402 || httpResponse.statusCode == 403 {
                logReadHTTPFailure(endpoint: endpoint, statusCode: httpResponse.statusCode, data: data)
                let message = decodeErrorMessage(data) ?? "Access denied for reminders."
                throw ReminderSyncServiceError.accessDenied(message: message)
            }

            if httpResponse.statusCode == 404 {
                logReadHTTPFailure(endpoint: endpoint, statusCode: httpResponse.statusCode, data: data)
                throw ReminderSyncServiceError.retryable(
                    message: missingFunctionDeploymentMessage(endpoint: endpoint)
                )
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

    private func post<T: Codable>(endpoint: String, body: T) async throws -> Data {
        guard let url = edgeFunctionURL(endpoint: endpoint, queryItems: []) else {
            throw ReminderSyncServiceError.missingBaseURL
        }

        var request = URLRequest(url: url)
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

            if httpResponse.statusCode == 404 {
                throw ReminderSyncServiceError.retryable(
                    message: missingFunctionDeploymentMessage(endpoint: endpoint)
                )
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

    private func classifyActionPayloadError(_ data: Data) -> ReminderSyncServiceError? {
        struct PayloadEnvelope: Decodable {
            struct PayloadError: Decodable {
                let code: String?
                let message: String?
                let retryable: Bool?
            }

            let ok: Bool?
            let message: String?
            let error: PayloadError?
            let errorCode: String?
            let errorMessage: String?
            let detail: String?

            enum CodingKeys: String, CodingKey {
                case ok
                case message
                case error
                case errorCode = "error_code"
                case errorMessage = "error_message"
                case detail
            }
        }

        guard let envelope = try? JSONDecoder().decode(PayloadEnvelope.self, from: data) else {
            return nil
        }

        let hasErrorSignal = envelope.ok == false ||
            envelope.error != nil ||
            envelope.errorCode != nil ||
            envelope.errorMessage != nil
        guard hasErrorSignal else { return nil }

        let message = sanitizeBackendMessage(
            envelope.error?.message ??
            envelope.errorMessage ??
            envelope.message ??
            envelope.detail
        ) ?? "Reminder action failed."

        let normalizedCode = normalizedCode(envelope.error?.code ?? envelope.errorCode)
        let normalizedMessage = message.lowercased()

        if isAccessLikeError(code: normalizedCode, message: normalizedMessage) ||
            isAuthLikeError(code: normalizedCode, message: normalizedMessage) {
            return .accessDenied(message: message)
        }

        if envelope.error?.retryable == true || isRetryableLikeError(code: normalizedCode, message: normalizedMessage) {
            return .retryable(message: message)
        }

        return .retryable(message: message)
    }

    private func classifyReadPayloadError(_ data: Data) -> ReminderSyncServiceError? {
        classifyActionPayloadError(data)
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

    private func missingFunctionDeploymentMessage(endpoint: String) -> String {
        "Backend function '\(endpoint)' is unavailable. Please deploy/update this Edge Function and retry."
    }

    private func sanitizeBackendMessage(_ message: String?) -> String? {
        guard let message else { return nil }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedCode(_ code: String?) -> String? {
        guard let code else { return nil }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        return trimmed.replacingOccurrences(of: "-", with: "_")
    }

    private func isAuthLikeError(code: String?, message: String) -> Bool {
        if let code, code.contains("unauthorized") || code.contains("auth") || code.contains("session") {
            return true
        }

        return message.contains("unauthorized") ||
            message.contains("session") ||
            message.contains("token") ||
            message.contains("log in")
    }

    private func isAccessLikeError(code: String?, message: String) -> Bool {
        if let code, code.contains("access") || code.contains("billing") || code.contains("trial") || code.contains("subscription") {
            return true
        }

        return message.contains("access") ||
            message.contains("trial") ||
            message.contains("subscription") ||
            message.contains("billing")
    }

    private func isRetryableLikeError(code: String?, message: String) -> Bool {
        if let code {
            if code.contains("retryable") || code.contains("processing_failed") || code.contains("internal_error") {
                return true
            }
        }

        return message.contains("try again") ||
            message.contains("temporarily unavailable") ||
            message.contains("timed out")
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
        print("[OneDone][RemoteRead] endpoint=\(endpoint) stage=http_failure status=\(statusCode) keys=\(keysDescription)")
#endif
    }

    private func logReadDecodeFailure(endpoint: String, data: Data) {
#if DEBUG
        let keys = topLevelJSONKeys(from: data)
        let keysDescription = keys.isEmpty ? "none" : keys.joined(separator: ",")
        print("[OneDone][RemoteRead] endpoint=\(endpoint) stage=decode_failure keys=\(keysDescription)")
#endif
    }

    private func logReadDispatch(endpoint: String, url: URL, queryItems: [URLQueryItem]) {
#if DEBUG
        let host = url.host ?? "unknown"
        let path = url.path
        let taskID = queryItems.first(where: { $0.name == "task_id" })?.value ?? "none"
        print("[OneDone][RemoteRead] endpoint=\(endpoint) stage=dispatching host=\(host) path=\(path) task_id=\(taskID)")
#endif
    }

    private func logReadResponseReceived(endpoint: String, statusCode: Int, data: Data) {
#if DEBUG
        let keys = topLevelJSONKeys(from: data)
        let keysDescription = keys.isEmpty ? "none" : keys.joined(separator: ",")
        print("[OneDone][RemoteRead] endpoint=\(endpoint) stage=response_received status=\(statusCode) keys=\(keysDescription)")
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
