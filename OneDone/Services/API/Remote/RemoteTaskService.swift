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

    // Local fallback used until answer-clarification endpoint is connected.
    func analyzeTask(prompt: String, template: TaskTemplate?) -> TaskDraft {
        MockRepository.makeDraft(prompt: prompt, template: template)
    }

    // Local fallback used until answer-clarification endpoint is connected.
    func answerClarification(answer: String, draft: TaskDraft) -> TaskDraft {
        MockRepository.applyClarification(answer: answer, to: draft)
    }

    // Local fallback used until full task actions are connected.
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

            if isAccessStatus(statusCode) {
                let message = payloadMessage(payload) ?? "Your current access does not allow creating new tasks."
                throw AnalyzeTaskServiceError.accessDenied(message: message)
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

    func messageMarkedSent(_ request: MessageMarkedSentRequest) throws -> MessageMarkedSentResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteTaskService", method: "messageMarkedSent")
    }

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteTaskService", method: "processIncomingReply")
    }

    private func mapPayload(_ payload: AnalyzeTaskResponseDTO) throws -> AnalyzeTaskServiceResponse {
        if case .accessError = payload.responseType {
            throw AnalyzeTaskServiceError.accessDenied(
                message: payloadMessage(payload) ?? "Your current access does not allow creating new tasks."
            )
        }

        if case .paywallError = payload.responseType {
            throw AnalyzeTaskServiceError.accessDenied(
                message: payloadMessage(payload) ?? "Start trial or subscription to continue creating tasks."
            )
        }

        if case .retryableError = payload.responseType {
            throw AnalyzeTaskServiceError.retryable(
                message: payloadMessage(payload) ?? "Task analysis is temporarily unavailable. Please retry."
            )
        }

        guard let taskID = payload.taskID, !taskID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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
        case .retryableError, .accessError, .paywallError:
            // Handled above.
            throw AnalyzeTaskServiceError.invalidResponse
        }
    }

    private func decodeAnalyzePayload(from data: Data) -> AnalyzeTaskResponseDTO? {
        let decoder = JSONDecoder()
        if let direct = try? decoder.decode(AnalyzeTaskResponseDTO.self, from: data) {
            return direct
        }

        if let wrapped = try? decoder.decode(AnalyzeTaskResponseWrapper.self, from: data) {
            return wrapped.data ?? wrapped.result ?? wrapped.response
        }

        return nil
    }

    private func payloadMessage(_ payload: AnalyzeTaskResponseDTO?) -> String? {
        payload?.error?.message ?? payload?.message
    }

    private func isAccessStatus(_ statusCode: Int) -> Bool {
        statusCode == 401 || statusCode == 402 || statusCode == 403 || statusCode == 423
    }

    private func isRetryableStatus(_ statusCode: Int) -> Bool {
        statusCode == 408 || statusCode == 409 || statusCode == 425 || statusCode == 429 || statusCode >= 500
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
}

private struct AnalyzeTaskResponseWrapper: Decodable {
    let data: AnalyzeTaskResponseDTO?
    let result: AnalyzeTaskResponseDTO?
    let response: AnalyzeTaskResponseDTO?
}
