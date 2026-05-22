import Foundation

struct RemoteTaskService: TaskServiceProtocol {
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

    // Local fallback for mock-safe mode and previews.
    func analyzeTask(prompt: String, template: TaskTemplate?) -> TaskDraft {
        MockRepository.makeDraft(prompt: prompt, template: template)
    }

    // Local fallback for mock-safe mode and previews.
    func answerClarification(answer: String, draft: TaskDraft) -> TaskDraft {
        MockRepository.applyClarification(answer: answer, to: draft)
    }

    // Local fallback for mock-safe mode and previews.
    func createTask(from draft: TaskDraft, status: TaskStatus) -> MockTask {
        MockRepository.makeTask(from: draft, status: status)
    }

    func submitAnalyzeTask(_ request: AnalyzeTaskRequest, idempotencyKey: String) async throws -> AnalyzeTaskServiceResponse {
        guard environment.useRemoteTaskAnalysis else {
            throw AnalyzeTaskServiceError.remoteAnalyzeDisabled
        }

        guard let baseURL = environment.baseURL else {
            throw AnalyzeTaskServiceError.missingBaseURL
        }

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("analyze-task"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")

        if let token = tokenProvider.accessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await urlSession.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnalyzeTaskServiceError.invalidResponse
            }

            let payload = decodeAnalyzePayload(from: data)
            let statusCode = httpResponse.statusCode
            logAnalyzeDiagnostics(statusCode: statusCode, payload: payload, data: data)

            if isAccessStatus(statusCode) {
                let message = payloadMessage(payload) ?? "Your current access does not allow creating new tasks."
                throw AnalyzeTaskServiceError.accessDenied(message: message)
            }

            if isRateLimitedStatus(statusCode) {
                let message = payloadMessage(payload) ?? "Too many requests right now. Please try again in a moment."
                throw AnalyzeTaskServiceError.rateLimited(message: message)
            }

            if isRetryableStatus(statusCode) {
                let message = payloadMessage(payload) ?? "Could not analyze this task right now. Please try again."
                throw AnalyzeTaskServiceError.retryable(message: message)
            }

            guard (200...299).contains(statusCode) else {
                let message = payloadMessage(payload) ?? "Task analysis failed. Please retry."
                throw AnalyzeTaskServiceError.retryable(message: message)
            }

            guard let payload else {
                throw AnalyzeTaskServiceError.invalidResponse
            }

            return try mapPayload(payload)
        } catch let error as AnalyzeTaskServiceError {
            throw error
        } catch let error as URLError {
            throw AnalyzeTaskServiceError.retryable(message: friendlyNetworkMessage(error))
        } catch {
            throw AnalyzeTaskServiceError.retryable(message: "Could not analyze this task right now. Please try again.")
        }
    }

    func submitAnswerClarification(_ request: AnswerClarificationRequest, idempotencyKey: String) async throws -> AnalyzeTaskServiceResponse {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/answer-clarification",
            body: request,
            idempotencyKey: idempotencyKey
        )

        guard let payload = decodeAnalyzePayload(from: data) else {
            throw TaskActionServiceError.invalidResponse
        }

        if case .accessError = payload.responseType {
            throw TaskActionServiceError.accessDenied(
                message: payloadMessage(payload) ?? "Your current access does not allow this action."
            )
        }

        if case .paywallError = payload.responseType {
            throw TaskActionServiceError.accessDenied(
                message: payloadMessage(payload) ?? "Start trial or subscription to continue."
            )
        }

        if case .retryableError = payload.responseType {
            throw TaskActionServiceError.retryable(
                message: payloadMessage(payload) ?? "Could not complete this clarification right now."
            )
        }

        if case .rateLimited = payload.responseType {
            throw TaskActionServiceError.retryable(
                message: payloadMessage(payload) ?? "Too many requests right now. Please try again in a moment."
            )
        }

        do {
            return try mapPayload(payload)
        } catch let error as AnalyzeTaskServiceError {
            switch error {
            case let .accessDenied(message):
                throw TaskActionServiceError.accessDenied(message: message)
            case let .retryable(message):
                throw TaskActionServiceError.retryable(message: message)
            case let .unsupportedResponse(message):
                throw TaskActionServiceError.unsupportedResponse(message: message)
            default:
                throw TaskActionServiceError.unsupportedResponse(message: error.errorDescription ?? "Could not parse clarification response.")
            }
        } catch {
            throw TaskActionServiceError.invalidResponse
        }
    }

    func submitGenerateReply(_ request: GenerateReplyRequest, idempotencyKey: String) async throws -> GenerateReplyResponse {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/generate-reply",
            body: request,
            idempotencyKey: idempotencyKey
        )

        if let payload = decodeSingleWrapper(data, as: GenerateReplyResponse.self) {
            return payload
        }

        throw TaskActionServiceError.invalidResponse
    }

    func submitUpdateTaskStatus(_ request: UpdateTaskStatusRequest, idempotencyKey: String) async throws -> UpdateTaskStatusResponse {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/update-task-status",
            body: request,
            idempotencyKey: idempotencyKey
        )

        if let payload = decodeSingleWrapper(data, as: UpdateTaskStatusResponse.self) {
            return payload
        }

        throw TaskActionServiceError.invalidResponse
    }

    func submitMessageMarkedSent(_ request: MessageMarkedSentRequest, idempotencyKey: String) async throws -> MessageMarkedSentResponse {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/message-marked-sent",
            body: request,
            idempotencyKey: idempotencyKey
        )

        if let payload = decodeSingleWrapper(data, as: MessageMarkedSentResponse.self) {
            return payload
        }

        throw TaskActionServiceError.invalidResponse
    }

    func fetchTaskList() async throws -> [BackendTaskSummaryDTO] {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        struct EmptyBody: Codable {}
        let data = try await postEdgeFunction(path: "functions/v1/list-tasks", body: EmptyBody(), idempotencyKey: nil)
        return decodeArrayWrapper(data, as: BackendTaskSummaryDTO.self) ?? []
    }

    func fetchTaskDetail(taskID: String) async throws -> BackendTaskDetailDTO? {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        struct RequestBody: Codable {
            let taskID: String
            enum CodingKeys: String, CodingKey {
                case taskID = "task_id"
            }
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/get-task-detail",
            body: RequestBody(taskID: taskID),
            idempotencyKey: nil
        )

        return decodeSingleWrapper(data, as: BackendTaskDetailDTO.self)
    }

    func fetchTaskOutputs(taskID: String) async throws -> [BackendTaskOutputDTO] {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        struct RequestBody: Codable {
            let taskID: String
            enum CodingKeys: String, CodingKey {
                case taskID = "task_id"
            }
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/get-task-outputs",
            body: RequestBody(taskID: taskID),
            idempotencyKey: nil
        )

        return decodeArrayWrapper(data, as: BackendTaskOutputDTO.self) ?? []
    }

    func fetchTaskEvents(taskID: String) async throws -> [BackendTaskEventDTO] {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        struct RequestBody: Codable {
            let taskID: String
            enum CodingKeys: String, CodingKey {
                case taskID = "task_id"
            }
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/get-task-events",
            body: RequestBody(taskID: taskID),
            idempotencyKey: nil
        )

        return decodeArrayWrapper(data, as: BackendTaskEventDTO.self) ?? []
    }

    func fetchChecklistItems(taskID: String) async throws -> [BackendChecklistItemDTO] {
        guard environment.useRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        struct RequestBody: Codable {
            let taskID: String
            enum CodingKeys: String, CodingKey {
                case taskID = "task_id"
            }
        }

        let data = try await postEdgeFunction(
            path: "functions/v1/get-checklist-items",
            body: RequestBody(taskID: taskID),
            idempotencyKey: nil
        )

        return decodeArrayWrapper(data, as: BackendChecklistItemDTO.self) ?? []
    }

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteTaskService", method: "processIncomingReply")
    }

    private func mapPayload(_ payload: AnalyzeTaskResponseDTO) throws -> AnalyzeTaskServiceResponse {
        if let classifiedError = classifyAnalyzePayloadError(payload) {
            throw classifiedError
        }

        guard let taskID = payload.taskID, !taskID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            if let message = payloadMessage(payload),
               !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AnalyzeTaskServiceError.unsupportedResponse(message: message)
            }

            throw AnalyzeTaskServiceError.missingTaskID
        }

        switch payload.responseType {
        case .clarification:
            let clarification = payload.clarification ?? AnalyzeTaskClarificationPayload(
                question: "I need one more detail before I can continue.",
                helperText: nil,
                options: [],
                title: nil
            )
            return .clarification(taskID: taskID, payload: clarification)
        case .taskAnalysis:
            let analysis = payload.taskAnalysis ?? AnalyzeTaskAnalysisPayload(
                title: nil,
                summary: payload.message,
                latestOutput: payload.message,
                checklist: [],
                nextSteps: [],
                category: nil
            )
            return .taskAnalysis(taskID: taskID, payload: analysis)
        case .multiTaskSplitPreview:
            let splitPayload = payload.multiTaskSplitPreview ?? AnalyzeTaskSplitPreviewPayload(
                title: "Multiple tasks detected",
                message: payload.message ?? "This input appears to include multiple tasks.",
                items: []
            )
            return .multiTaskSplitPreview(taskID: taskID, payload: splitPayload)
        case .unknown:
            if let clarification = payload.clarification {
                return .clarification(taskID: taskID, payload: clarification)
            }

            if let analysis = payload.taskAnalysis {
                return .taskAnalysis(taskID: taskID, payload: analysis)
            }

            if let splitPayload = payload.multiTaskSplitPreview {
                return .multiTaskSplitPreview(taskID: taskID, payload: splitPayload)
            }

            throw AnalyzeTaskServiceError.unsupportedResponse(
                message: payloadMessage(payload) ?? "Received an unsupported task analysis response."
            )
        case .retryableError, .rateLimited, .accessError, .paywallError:
            // Handled above.
            throw AnalyzeTaskServiceError.invalidResponse
        }
    }

    private func decodeAnalyzePayload(from data: Data) -> AnalyzeTaskResponseDTO? {
        if let direct = decodeSingleWrapper(data, as: AnalyzeTaskResponseDTO.self) {
            return direct
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }

        for candidate in analyzePayloadCandidates(from: jsonObject) {
            guard JSONSerialization.isValidJSONObject(candidate),
                  let candidateData = try? JSONSerialization.data(withJSONObject: candidate),
                  var payload = decodeSingleWrapper(candidateData, as: AnalyzeTaskResponseDTO.self) else {
                continue
            }

            enrichAnalyzePayload(&payload, withRootJSONObject: jsonObject)

            if hasAnalyzeSignal(payload) {
                return payload
            }
        }

        return nil
    }

    private func payloadMessage(_ payload: AnalyzeTaskResponseDTO?) -> String? {
        sanitizeBackendMessage(payload?.error?.message ?? payload?.message)
    }

    private func isAccessStatus(_ statusCode: Int) -> Bool {
        statusCode == 401 || statusCode == 402 || statusCode == 403 || statusCode == 423
    }

    private func isRetryableStatus(_ statusCode: Int) -> Bool {
        statusCode == 408 || statusCode == 409 || statusCode == 425 || statusCode >= 500
    }

    private func isRateLimitedStatus(_ statusCode: Int) -> Bool {
        statusCode == 429
    }

    private func friendlyNetworkMessage(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "You appear to be offline. Connect to the internet and retry."
        case .timedOut:
            return "Task analysis timed out. Please try again."
        default:
            return "Network issue while analyzing the task. Please try again."
        }
    }

    private func postEdgeFunction<T: Codable>(
        path: String,
        body: T,
        idempotencyKey: String?
    ) async throws -> Data {
        guard let baseURL = environment.baseURL else {
            throw TaskActionServiceError.missingBaseURL
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let idempotencyKey, !idempotencyKey.isEmpty {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }

        if let token = tokenProvider.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TaskActionServiceError.invalidResponse
            }

            if isAccessStatus(httpResponse.statusCode) {
                let message = decodeErrorMessage(data) ?? "Your current access does not allow this action."
                throw TaskActionServiceError.accessDenied(message: message)
            }

            if isRetryableStatus(httpResponse.statusCode) {
                let message = decodeErrorMessage(data) ?? "Action is temporarily unavailable. Please try again."
                throw TaskActionServiceError.retryable(message: message)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = decodeErrorMessage(data) ?? "Action failed."
                throw TaskActionServiceError.retryable(message: message)
            }

            return data
        } catch let error as TaskActionServiceError {
            throw error
        } catch let error as URLError {
            throw TaskActionServiceError.retryable(message: friendlyNetworkMessage(error))
        } catch {
            throw TaskActionServiceError.retryable(message: "Action failed. Please try again.")
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

        if let wrapped = try? JSONDecoder().decode(AnalyzeTaskResponseWrapper<T>.self, from: data) {
            return wrapped.data ?? wrapped.result ?? wrapped.response ?? wrapped.payload
        }

        return nil
    }

    private func decodeArrayWrapper<T: Decodable>(_ data: Data, as type: T.Type) -> [T]? {
        if let direct = try? JSONDecoder().decode([T].self, from: data) {
            return direct
        }

        if let wrapped = try? JSONDecoder().decode(AnalyzeTaskArrayResponseWrapper<T>.self, from: data) {
            return wrapped.data ?? wrapped.result ?? wrapped.response ?? wrapped.payload
        }

        return nil
    }

    private func classifyAnalyzePayloadError(_ payload: AnalyzeTaskResponseDTO) -> AnalyzeTaskServiceError? {
        switch payload.responseType {
        case .accessError:
            return .accessDenied(
                message: payloadMessage(payload) ?? "Your current access does not allow creating new tasks."
            )
        case .paywallError:
            return .accessDenied(
                message: payloadMessage(payload) ?? "Start trial or subscription to continue creating tasks."
            )
        case .retryableError:
            return .retryable(
                message: payloadMessage(payload) ?? "Task analysis is temporarily unavailable. Please retry."
            )
        case .rateLimited:
            return .rateLimited(
                message: payloadMessage(payload) ?? "Too many requests right now. Please try again in a moment."
            )
        case .clarification, .taskAnalysis, .multiTaskSplitPreview, .unknown:
            break
        }

        let errorCode = normalizedCode(payload.error?.code)
        let message = payloadMessage(payload)?.lowercased() ?? ""
        let hasSuccessPayload =
            payload.clarification != nil ||
            payload.taskAnalysis != nil ||
            payload.multiTaskSplitPreview != nil
        let hasErrorPayload = payload.error != nil
        let shouldUseErrorHeuristics =
            hasErrorPayload ||
            (payload.responseType == .unknown && !hasSuccessPayload)

        if !shouldUseErrorHeuristics {
            return nil
        }

        if errorCode == "rate_limited" || message.contains("rate limit") || message.contains("too many requests") {
            return .rateLimited(
                message: payloadMessage(payload) ?? "Too many requests right now. Please try again in a moment."
            )
        }

        if isAccessLikeError(code: errorCode, message: message) {
            return .accessDenied(
                message: payloadMessage(payload) ?? "Your current access does not allow creating new tasks."
            )
        }

        if isAuthLikeError(code: errorCode, message: message) {
            return .accessDenied(
                message: "Your session expired. Please log in again."
            )
        }

        if isValidationLikeError(code: errorCode, message: message) {
            return .unsupportedResponse(
                message: "Please check your task text and try again."
            )
        }

        if payload.error?.retryable == true || isRetryableLikeError(code: errorCode, message: message) {
            return .retryable(
                message: payloadMessage(payload) ?? "Could not analyze this task right now. Please try again."
            )
        }

        if hasErrorPayload {
            return .retryable(
                message: payloadMessage(payload) ?? "Could not analyze this task right now. Please try again."
            )
        }

        return nil
    }

    private func isAuthLikeError(code: String?, message: String) -> Bool {
        if let code {
            if code.contains("auth") || code.contains("session") || code.contains("token") || code.contains("unauthorized") {
                return true
            }
        }

        return message.contains("jwt") ||
            message.contains("token") ||
            message.contains("session") ||
            message.contains("unauthorized") ||
            message.contains("forbidden")
    }

    private func isAccessLikeError(code: String?, message: String) -> Bool {
        if let code {
            if code.contains("access") ||
                code.contains("paywall") ||
                code.contains("trial") ||
                code.contains("subscription") ||
                code.contains("starter") ||
                code.contains("billing_issue") ||
                code.contains("grace_period") {
                return true
            }
        }

        return message.contains("access") ||
            message.contains("trial") ||
            message.contains("subscription") ||
            message.contains("starter") ||
            message.contains("billing") ||
            message.contains("paywall")
    }

    private func isValidationLikeError(code: String?, message: String) -> Bool {
        if let code {
            if code.contains("validation") ||
                code.contains("invalid_input") ||
                code.contains("bad_request") ||
                code.contains("missing_input") ||
                code.contains("missing_fields") ||
                code.contains("parse_error") {
                return true
            }
        }

        return message.contains("validation") ||
            message.contains("invalid") ||
            message.contains("missing") ||
            message.contains("parse request body as json") ||
            message.contains("unexpected end of json input")
    }

    private func isRetryableLikeError(code: String?, message: String) -> Bool {
        if let code {
            if code.contains("retryable") ||
                code.contains("processing_error") ||
                code.contains("temporary") ||
                code.contains("timeout") {
                return true
            }
        }

        return message.contains("try again") ||
            message.contains("temporarily unavailable") ||
            message.contains("timeout")
    }

    private func normalizedCode(_ code: String?) -> String? {
        guard let code else { return nil }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        return trimmed.replacingOccurrences(of: "-", with: "_")
    }

    private func sanitizeBackendMessage(_ message: String?) -> String? {
        guard let message else { return nil }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowercased = trimmed.lowercased()
        if lowercased.contains("could not parse request body as json") ||
            lowercased.contains("unexpected end of json input") {
            return "Please check your task text and try again."
        }

        if lowercased.contains("jwt") && lowercased.contains("expired") {
            return "Your session expired. Please log in again."
        }

        return trimmed
    }

    private func hasAnalyzeSignal(_ payload: AnalyzeTaskResponseDTO) -> Bool {
        if payload.responseType != .unknown {
            return true
        }

        return payload.taskID != nil ||
            payload.clarification != nil ||
            payload.taskAnalysis != nil ||
            payload.multiTaskSplitPreview != nil ||
            payload.error != nil ||
            payload.message != nil
    }

    private func analyzePayloadCandidates(from object: Any) -> [[String: Any]] {
        var candidates: [[String: Any]] = []
        var queue: [(node: Any, depth: Int)] = [(object, 0)]
        let preferredKeys: Set<String> = ["data", "result", "response", "payload"]
        let maxDepth = 4

        while let current = queue.first {
            queue.removeFirst()
            guard current.depth <= maxDepth else { continue }

            if let dictionary = current.node as? [String: Any] {
                candidates.append(dictionary)

                for key in preferredKeys {
                    if let nested = dictionary[key] {
                        queue.append((nested, current.depth + 1))
                    }
                }

                for value in dictionary.values {
                    if value is [String: Any] || value is [Any] {
                        queue.append((value, current.depth + 1))
                    }
                }
            } else if let array = current.node as? [Any] {
                for value in array where value is [String: Any] || value is [Any] {
                    queue.append((value, current.depth + 1))
                }
            }
        }

        return candidates
    }

    private func enrichAnalyzePayload(_ payload: inout AnalyzeTaskResponseDTO, withRootJSONObject root: Any) {
        guard let rootDictionary = root as? [String: Any] else { return }

        if payload.taskID == nil {
            payload.taskID = jsonStringValue(in: rootDictionary, keys: ["task_id", "taskId", "id"])
            if payload.taskID == nil,
               let taskObject = rootDictionary["task"] as? [String: Any] {
                payload.taskID = jsonStringValue(in: taskObject, keys: ["id", "task_id"])
            }
        }

        if payload.responseType == .unknown,
           let responseType = jsonStringValue(in: rootDictionary, keys: ["response_type", "responseType", "type"]) {
            payload.responseType = AnalyzeTaskResponseType(rawValue: responseType) ?? .unknown
        }

        if payload.message == nil {
            payload.message = jsonStringValue(
                in: rootDictionary,
                keys: ["message", "status_message", "detail", "error_message", "error_description"]
            )
        }

        if payload.error == nil {
            let errorCode = jsonStringValue(in: rootDictionary, keys: ["error_code"])
            let errorMessage = jsonStringValue(in: rootDictionary, keys: ["error_message", "error_description", "detail"])
            if errorCode != nil || errorMessage != nil {
                payload.error = AnalyzeTaskErrorPayload(
                    code: errorCode,
                    message: errorMessage,
                    retryable: nil
                )
            }
        }
    }

    private func jsonStringValue(in dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }

            if let intValue = dictionary[key] as? Int {
                return String(intValue)
            }
        }
        return nil
    }

    private func logAnalyzeDiagnostics(statusCode: Int, payload: AnalyzeTaskResponseDTO?, data: Data) {
#if DEBUG
        let responseTypeDescription: String
        if let payload {
            responseTypeDescription = "\(payload.responseType)"
        } else {
            responseTypeDescription = "unparsed"
        }

        let keys = topLevelJSONKeys(from: data)
        let keysDescription = keys.isEmpty ? "none" : keys.joined(separator: ",")
        print("[OneDone][AnalyzeTask] status=\(statusCode) responseType=\(responseTypeDescription) topLevelKeys=\(keysDescription)")
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

private struct AnalyzeTaskResponseWrapper<T: Decodable>: Decodable {
    let data: T?
    let result: T?
    let response: T?
    let payload: T?
}

private struct AnalyzeTaskArrayResponseWrapper<T: Decodable>: Decodable {
    let data: [T]?
    let result: [T]?
    let response: [T]?
    let payload: [T]?
}
