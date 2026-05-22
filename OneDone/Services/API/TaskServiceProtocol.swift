import Foundation

protocol TaskServiceProtocol {
    func analyzeTask(prompt: String, template: TaskTemplate?) -> TaskDraft
    func answerClarification(answer: String, draft: TaskDraft) -> TaskDraft
    func createTask(from draft: TaskDraft, status: TaskStatus) -> MockTask

    func messageMarkedSent(_ request: MessageMarkedSentRequest) throws -> MessageMarkedSentResponse
    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse
}
