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

    func messageMarkedSent(_ request: MessageMarkedSentRequest) throws -> MessageMarkedSentResponse {
        MessageMarkedSentResponse(taskID: request.taskID, status: "waiting_for_reply")
    }

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse {
        ProcessIncomingReplyResponse(taskID: request.taskID, status: "processed_mock")
    }
}
