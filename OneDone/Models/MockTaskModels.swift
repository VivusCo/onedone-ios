import Foundation

enum TaskStatus: String, CaseIterable, Identifiable, Hashable {
    case draft = "Draft"
    case inProgress = "In progress"
    case ready = "Ready"
    case done = "Done"

    var id: String { rawValue }
}

struct TaskTemplate: Identifiable, Hashable {
    let id: UUID
    let title: String
    let promptHint: String
    let focus: String

    init(id: UUID = UUID(), title: String, promptHint: String, focus: String) {
        self.id = id
        self.title = title
        self.promptHint = promptHint
        self.focus = focus
    }
}

struct TaskDraft: Identifiable, Hashable {
    let id: UUID
    var title: String
    var prompt: String
    var clarificationQuestion: String
    var clarificationAnswer: String
    var generatedReply: String
    var actionPlan: [String]

    init(
        id: UUID = UUID(),
        title: String,
        prompt: String,
        clarificationQuestion: String,
        clarificationAnswer: String = "",
        generatedReply: String,
        actionPlan: [String]
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.clarificationQuestion = clarificationQuestion
        self.clarificationAnswer = clarificationAnswer
        self.generatedReply = generatedReply
        self.actionPlan = actionPlan
    }
}

struct MockTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var prompt: String
    var clarification: String
    var generatedReply: String
    var actionPlan: [String]
    var createdAt: Date
    var dueDate: Date?
    var status: TaskStatus

    init(
        id: UUID = UUID(),
        title: String,
        prompt: String,
        clarification: String,
        generatedReply: String,
        actionPlan: [String],
        createdAt: Date,
        dueDate: Date?,
        status: TaskStatus
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.clarification = clarification
        self.generatedReply = generatedReply
        self.actionPlan = actionPlan
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.status = status
    }
}
