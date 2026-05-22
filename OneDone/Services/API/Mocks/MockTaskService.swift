import Foundation

struct MockTaskService: TaskServiceProtocol {
    func analyzeTask(prompt: String, template: TaskTemplate?) -> TaskDraft {
        MockRepository.makeDraft(prompt: prompt, template: template)
    }

    func answerClarification(answer: String, draft: TaskDraft) -> TaskDraft {
        MockRepository.applyClarification(answer: answer, to: draft)
    }

    func createTask(from draft: TaskDraft, status: TaskStatus) -> MockTask {
        MockRepository.makeTask(from: draft, status: status)
    }

    func submitAnalyzeTask(_ request: AnalyzeTaskRequest, idempotencyKey: String) async throws -> AnalyzeTaskServiceResponse {
        let template = MockRepository.templates.first(where: { $0.backendTemplateID == request.selectedTemplate })
        let draft = MockRepository.makeDraft(prompt: request.inputText, template: template)
        let taskID = "mock-\(UUID().uuidString)"

        if draft.requiresClarification {
            return .clarification(
                taskID: taskID,
                payload: AnalyzeTaskClarificationPayload(
                    question: draft.clarificationQuestion,
                    helperText: "To give the right steps, I need one detail.",
                    options: draft.clarificationOptions,
                    title: draft.title
                )
            )
        }

        return .taskAnalysis(
            taskID: taskID,
            payload: AnalyzeTaskAnalysisPayload(
                title: draft.title,
                summary: draft.generatedReply,
                latestOutput: draft.generatedReply,
                checklist: draft.actionPlan,
                nextSteps: draft.actionPlan,
                category: draft.intent == .cancelSubscription ? "Subscription" : "General"
            )
        )
    }

    func submitAnswerClarification(_ request: AnswerClarificationRequest, idempotencyKey: String) async throws -> AnalyzeTaskServiceResponse {
        .taskAnalysis(
            taskID: request.taskID,
            payload: AnalyzeTaskAnalysisPayload(
                title: "Updated task",
                summary: "Clarification received in mock mode.",
                latestOutput: "Clarification received in mock mode.",
                checklist: [
                    "Review clarification details",
                    "Continue with next action"
                ],
                nextSteps: [
                    "Continue with next action"
                ],
                category: "General"
            )
        )
    }

    func submitGenerateReply(_ request: GenerateReplyRequest, idempotencyKey: String) async throws -> GenerateReplyResponse {
        let toneLabel = request.tone ?? "Polite"
        let languageLabel = request.language ?? "Auto"
        return GenerateReplyResponse(
            taskID: request.taskID,
            subject: "Regarding your request",
            message: "[\(toneLabel)] [\(languageLabel)] Thanks for your message. Here is a clear next step we can take."
        )
    }

    func submitUpdateTaskStatus(_ request: UpdateTaskStatusRequest, idempotencyKey: String) async throws -> UpdateTaskStatusResponse {
        UpdateTaskStatusResponse(
            taskID: request.taskID,
            status: request.status,
            message: "Mock status update synced."
        )
    }

    func submitMessageMarkedSent(_ request: MessageMarkedSentRequest, idempotencyKey: String) async throws -> MessageMarkedSentResponse {
        MessageMarkedSentResponse(taskID: request.taskID, status: "waiting_for_reply", message: "Mock message-marked-sent synced.")
    }

    func fetchTaskList() async throws -> [BackendTaskSummaryDTO] {
        []
    }

    func fetchTaskDetail(taskID: String) async throws -> BackendTaskDetailDTO? {
        nil
    }

    func fetchTaskOutputs(taskID: String) async throws -> [BackendTaskOutputDTO] {
        []
    }

    func fetchTaskEvents(taskID: String) async throws -> [BackendTaskEventDTO] {
        []
    }

    func fetchChecklistItems(taskID: String) async throws -> [BackendChecklistItemDTO] {
        []
    }

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse {
        ProcessIncomingReplyResponse(taskID: request.taskID, status: "processed_mock")
    }
}
