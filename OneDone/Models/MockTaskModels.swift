import Foundation

enum TaskStatus: String, CaseIterable, Identifiable, Hashable {
    case new = "New"
    case followUpNeeded = "Follow-up Needed"
    case dueSoon = "Due Soon"
    case needsClarification = "Needs Clarification"
    case waitingForReply = "Waiting for Reply"
    case inProgress = "In Progress"
    case postponed = "Postponed"
    case ready = "Ready"
    case done = "Done"
    case draft = "Draft"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .ready, .draft:
            return TaskStatus.new.rawValue
        default:
            return rawValue
        }
    }

    var sortPriority: Int {
        switch self {
        case .followUpNeeded:
            return 1
        case .dueSoon:
            return 2
        case .needsClarification:
            return 3
        case .waitingForReply:
            return 4
        case .inProgress:
            return 5
        case .new, .ready, .draft:
            return 6
        case .postponed:
            return 7
        case .done:
            return 8
        }
    }
}

enum MyTasksFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case needsClarification = "Needs Clarification"
    case followUpNeeded = "Follow-up Needed"
    case dueSoon = "Due Soon"
    case waitingForReply = "Waiting for Reply"
    case inProgress = "In Progress"
    case done = "Done"

    var id: String { rawValue }

    func matches(_ status: TaskStatus) -> Bool {
        switch self {
        case .all:
            return true
        case .needsClarification:
            return status == .needsClarification
        case .followUpNeeded:
            return status == .followUpNeeded
        case .dueSoon:
            return status == .dueSoon
        case .waitingForReply:
            return status == .waitingForReply
        case .inProgress:
            return status == .inProgress
        case .done:
            return status == .done
        }
    }
}

enum TaskIntent: String, Hashable {
    case generic
    case cancelSubscription
}

struct TaskTimelineEntry: Identifiable, Hashable {
    let id: UUID
    var title: String
    var detail: String
    var date: Date

    init(id: UUID = UUID(), title: String, detail: String, date: Date) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
    }
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
    var intent: TaskIntent
    var requiresClarification: Bool
    var clarificationQuestion: String
    var clarificationOptions: [String]
    var clarificationAnswer: String
    var generatedReply: String
    var actionPlan: [String]

    init(
        id: UUID = UUID(),
        title: String,
        prompt: String,
        intent: TaskIntent = .generic,
        requiresClarification: Bool = false,
        clarificationQuestion: String,
        clarificationOptions: [String] = [],
        clarificationAnswer: String = "",
        generatedReply: String,
        actionPlan: [String]
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.intent = intent
        self.requiresClarification = requiresClarification
        self.clarificationQuestion = clarificationQuestion
        self.clarificationOptions = clarificationOptions
        self.clarificationAnswer = clarificationAnswer
        self.generatedReply = generatedReply
        self.actionPlan = actionPlan
    }
}

struct MockTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var prompt: String
    var clarification: String
    var generatedReply: String
    var latestAIOutput: String
    var replyDraft: String?
    var currentNextStep: String
    var lastEventPreview: String
    var actionPlan: [String]
    var timeline: [TaskTimelineEntry]
    var createdAt: Date
    var dueDate: Date?
    var reminderDate: Date?
    var reminderNotificationID: String?
    var status: TaskStatus

    init(
        id: UUID = UUID(),
        title: String,
        category: String = "General",
        prompt: String,
        clarification: String,
        generatedReply: String,
        actionPlan: [String],
        createdAt: Date,
        dueDate: Date?,
        status: TaskStatus,
        latestAIOutput: String? = nil,
        replyDraft: String? = nil,
        currentNextStep: String? = nil,
        lastEventPreview: String? = nil,
        reminderDate: Date? = nil,
        reminderNotificationID: String? = nil,
        timeline: [TaskTimelineEntry] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.prompt = prompt
        self.clarification = clarification
        self.generatedReply = generatedReply
        self.latestAIOutput = latestAIOutput ?? generatedReply
        self.replyDraft = replyDraft
        self.currentNextStep = currentNextStep ?? actionPlan.first ?? "Review the task and continue."
        self.lastEventPreview = lastEventPreview ?? "Task created."
        self.actionPlan = actionPlan
        self.timeline = timeline
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.reminderNotificationID = reminderNotificationID
        self.status = status
    }
}
