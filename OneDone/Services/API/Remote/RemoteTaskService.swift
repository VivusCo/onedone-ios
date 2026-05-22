import Foundation

struct RemoteTaskService: TaskServiceProtocol {
    func analyzeTask(prompt: String, template: TaskTemplate?) -> TaskDraft {
        fatalError("TODO: implement RemoteTaskService.analyzeTask with backend client (disabled in IOS-12 scaffold)")
    }

    func answerClarification(answer: String, draft: TaskDraft) -> TaskDraft {
        fatalError("TODO: implement RemoteTaskService.answerClarification with backend client (disabled in IOS-12 scaffold)")
    }

    func createTask(from draft: TaskDraft, status: TaskStatus) -> MockTask {
        fatalError("TODO: implement RemoteTaskService.createTask with backend client (disabled in IOS-12 scaffold)")
    }

    func messageMarkedSent(_ request: MessageMarkedSentRequest) throws -> MessageMarkedSentResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteTaskService", method: "messageMarkedSent")
    }

    func processIncomingReply(_ request: ProcessIncomingReplyRequest) throws -> ProcessIncomingReplyResponse {
        throw ServiceScaffoldError.notImplemented(service: "RemoteTaskService", method: "processIncomingReply")
    }
}
