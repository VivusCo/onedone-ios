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

    func messageMarkedSent(_ request: MessageMarkedSentRequest) throws -> MessageMarkedSentResponse {
        MessageMarkedSentResponse(taskID: request.taskID, status: "waiting_for_reply")
    }

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse {
        ProcessIncomingReplyResponse(taskID: request.taskID, status: "processed_mock")
    }
}
