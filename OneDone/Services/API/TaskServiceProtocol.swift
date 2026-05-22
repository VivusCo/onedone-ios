import Foundation

enum AnalyzeTaskServiceError: LocalizedError {
    case remoteAnalyzeDisabled
    case missingBaseURL
    case accessDenied(message: String)
    case retryable(message: String)
    case invalidResponse
    case missingTaskID
    case unsupportedResponse(message: String)

    var errorDescription: String? {
        switch self {
        case .remoteAnalyzeDisabled:
            return "Remote task analysis is disabled."
        case .missingBaseURL:
            return "OneDone API base URL is missing. Configure ONEDONE_API_BASE_URL to enable remote task analysis."
        case let .accessDenied(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Could not understand the task analysis response."
        case .missingTaskID:
            return "Task analysis response is missing task_id."
        case let .unsupportedResponse(message):
            return message
        }
    }
}

enum TaskActionServiceError: LocalizedError {
    case remoteActionsDisabled
    case missingBaseURL
    case missingBackendTaskID
    case accessDenied(message: String)
    case retryable(message: String)
    case invalidResponse
    case unsupportedResponse(message: String)

    var errorDescription: String? {
        switch self {
        case .remoteActionsDisabled:
            return "Remote task actions are disabled."
        case .missingBaseURL:
            return "OneDone API base URL is missing. Configure ONEDONE_API_BASE_URL to enable remote task actions."
        case .missingBackendTaskID:
            return "This task is local-only and cannot be synced to backend yet."
        case let .accessDenied(message):
            return message
        case let .retryable(message):
            return message
        case .invalidResponse:
            return "Could not understand backend action response."
        case let .unsupportedResponse(message):
            return message
        }
    }
}

enum AnalyzeTaskServiceResponse {
    case clarification(taskID: String, payload: AnalyzeTaskClarificationPayload)
    case taskAnalysis(taskID: String, payload: AnalyzeTaskAnalysisPayload)
    case multiTaskSplitPreview(taskID: String, payload: AnalyzeTaskSplitPreviewPayload)
}

protocol TaskServiceProtocol {
    func analyzeTask(prompt: String, template: TaskTemplate?) -> TaskDraft
    func answerClarification(answer: String, draft: TaskDraft) -> TaskDraft
    func createTask(from draft: TaskDraft, status: TaskStatus) -> MockTask
    func submitAnalyzeTask(_ request: AnalyzeTaskRequest, idempotencyKey: String) async throws -> AnalyzeTaskServiceResponse
    func submitAnswerClarification(_ request: AnswerClarificationRequest, idempotencyKey: String) async throws -> AnalyzeTaskServiceResponse
    func submitGenerateReply(_ request: GenerateReplyRequest, idempotencyKey: String) async throws -> GenerateReplyResponse
    func submitUpdateTaskStatus(_ request: UpdateTaskStatusRequest, idempotencyKey: String) async throws -> UpdateTaskStatusResponse
    func submitMessageMarkedSent(_ request: MessageMarkedSentRequest, idempotencyKey: String) async throws -> MessageMarkedSentResponse
    func fetchTaskList() async throws -> [BackendTaskSummaryDTO]
    func fetchTaskDetail(taskID: String) async throws -> BackendTaskDetailDTO?
    func fetchTaskOutputs(taskID: String) async throws -> [BackendTaskOutputDTO]
    func fetchTaskEvents(taskID: String) async throws -> [BackendTaskEventDTO]
    func fetchChecklistItems(taskID: String) async throws -> [BackendChecklistItemDTO]

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse
}
