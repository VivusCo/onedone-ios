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

    func messageMarkedSent(_ request: MessageMarkedSentRequest) throws -> MessageMarkedSentResponse
    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse
}
