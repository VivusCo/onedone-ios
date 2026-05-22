import Foundation

enum APIAccessState: String, Codable, CaseIterable {
    case unauthenticated
    case onboarding_required
    case starter_active
    case starter_expired
    case trial_not_started
    case trial_active
    case subscription_active
    case subscription_cancelled_active
    case grace_period
    case billing_issue
    case trial_expired
    case subscription_expired
}

struct APIAccessStatePayload: Codable {
    var accessState: APIAccessState
    var starterDaysRemaining: Int?
    var statusNote: String?

    enum CodingKeys: String, CodingKey {
        case accessState = "access_state"
        case starterDaysRemaining = "starter_days_remaining"
        case statusNote = "status_note"
    }
}

struct CompleteOnboardingRequest: Codable {
    var userID: String?
}

struct CompleteOnboardingResponse: Codable {
    var access: APIAccessStatePayload
}

struct GetAccessStateResponse: Codable {
    var access: APIAccessStatePayload
}

struct GetAccessStateDTO: Decodable {
    let access: APIAccessStatePayload

    enum CodingKeys: String, CodingKey {
        case access
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.access) {
            access = try container.decode(APIAccessStatePayload.self, forKey: .access)
        } else {
            access = try APIAccessStatePayload(from: decoder)
        }
    }
}

struct AnalyzeTaskRequest: Codable {
    var inputText: String
    var selectedTemplate: String?
    var deadlineAtISO8601: String?
    var contextNotes: String?

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case selectedTemplate = "selected_template"
        case deadlineAtISO8601 = "deadline_at"
        case contextNotes = "context_notes"
    }
}

enum AnalyzeTaskResponseType: String, Codable {
    case clarification
    case taskAnalysis = "task_analysis"
    case multiTaskSplitPreview = "multi_task_split_preview"
    case retryableError = "retryable_error"
    case accessError = "access_error"
    case paywallError = "paywall_error"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        self = AnalyzeTaskResponseType(rawValue: rawValue) ?? .unknown
    }
}

struct AnalyzeTaskClarificationPayload: Decodable {
    var question: String?
    var helperText: String?
    var options: [String]
    var title: String?

    enum CodingKeys: String, CodingKey {
        case question
        case helperText = "helper_text"
        case options
        case title
    }
}

struct AnalyzeTaskAnalysisPayload: Decodable {
    var title: String?
    var summary: String?
    var latestOutput: String?
    var checklist: [String]
    var nextSteps: [String]
    var category: String?

    enum CodingKeys: String, CodingKey {
        case title
        case summary
        case latestOutput = "latest_output"
        case checklist
        case nextSteps = "next_steps"
        case category
    }
}

struct AnalyzeTaskSplitPreviewItem: Decodable {
    var id: String?
    var title: String
}

struct AnalyzeTaskSplitPreviewPayload: Decodable {
    var title: String?
    var message: String?
    var items: [AnalyzeTaskSplitPreviewItem]

    enum CodingKeys: String, CodingKey {
        case title
        case message
        case items
    }
}

struct AnalyzeTaskErrorPayload: Decodable {
    var code: String?
    var message: String?
    var retryable: Bool?
}

struct AnalyzeTaskResponseDTO: Decodable {
    var taskID: String?
    var responseType: AnalyzeTaskResponseType
    var clarification: AnalyzeTaskClarificationPayload?
    var taskAnalysis: AnalyzeTaskAnalysisPayload?
    var multiTaskSplitPreview: AnalyzeTaskSplitPreviewPayload?
    var error: AnalyzeTaskErrorPayload?
    var message: String?
    var access: APIAccessStatePayload?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case responseType = "response_type"
        case clarification
        case taskAnalysis = "task_analysis"
        case multiTaskSplitPreview = "multi_task_split_preview"
        case error
        case message
        case access
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskID = try container.decodeIfPresent(String.self, forKey: .taskID)
        responseType = try container.decodeIfPresent(AnalyzeTaskResponseType.self, forKey: .responseType) ?? .unknown
        clarification = try container.decodeIfPresent(AnalyzeTaskClarificationPayload.self, forKey: .clarification)
        taskAnalysis = try container.decodeIfPresent(AnalyzeTaskAnalysisPayload.self, forKey: .taskAnalysis)
        multiTaskSplitPreview = try container.decodeIfPresent(AnalyzeTaskSplitPreviewPayload.self, forKey: .multiTaskSplitPreview)
        error = try container.decodeIfPresent(AnalyzeTaskErrorPayload.self, forKey: .error)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        access = try container.decodeIfPresent(APIAccessStatePayload.self, forKey: .access)
    }
}

struct AnalyzeTaskResponse: Codable {
    var taskID: String
    var needsClarification: Bool
    var clarificationQuestion: String?
    var clarificationOptions: [String]?
}

struct AnswerClarificationRequest: Codable {
    var taskID: String
    var answer: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case answer
    }
}

struct AnswerClarificationResponse: Codable {
    var taskID: String
    var nextStepSummary: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case nextStepSummary = "next_step_summary"
    }
}

struct GenerateReplyRequest: Codable {
    var taskID: String
    var tone: String?
    var language: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case tone
        case language
    }
}

struct GenerateReplyResponse: Codable {
    var taskID: String
    var subject: String?
    var message: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case subject
        case message
    }
}

struct ValidateSubscriptionRequest: Codable {
    var transactionID: String
}

struct ValidateSubscriptionResponse: Codable {
    var access: APIAccessStatePayload
}

struct RestorePurchasesResponse: Codable {
    var access: APIAccessStatePayload
}

struct MessageMarkedSentRequest: Codable {
    var taskID: String
    var sentAtISO8601: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case sentAtISO8601 = "sent_at"
    }
}

struct MessageMarkedSentResponse: Codable {
    var taskID: String
    var status: String
    var message: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case status
        case message
    }
}

struct ProcessIncomingReplyRequest: Codable {
    var taskID: String
    var replyText: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case replyText = "reply_text"
    }
}

struct ProcessIncomingReplyResponse: Codable {
    var taskID: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case status
    }
}

struct UpdateTaskStatusRequest: Codable {
    var taskID: String
    var status: String
    var reason: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case status
        case reason
    }
}

struct UpdateTaskStatusResponse: Codable {
    var taskID: String
    var status: String
    var message: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case status
        case message
    }
}

struct ReminderCreateRequest: Codable {
    var taskID: String
    var remindAtISO8601: String
    var iosNotificationID: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case remindAtISO8601 = "remind_at"
        case iosNotificationID = "ios_notification_id"
    }
}

struct ReminderUpdateRequest: Codable {
    var taskID: String
    var reminderID: String?
    var remindAtISO8601: String
    var iosNotificationID: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case reminderID = "reminder_id"
        case remindAtISO8601 = "remind_at"
        case iosNotificationID = "ios_notification_id"
    }
}

struct ReminderCancelRequest: Codable {
    var taskID: String
    var reminderID: String?
    var iosNotificationID: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case reminderID = "reminder_id"
        case iosNotificationID = "ios_notification_id"
    }
}

struct ReminderSnoozeRequest: Codable {
    var taskID: String
    var reminderID: String?
    var iosNotificationID: String
    var remindAtISO8601: String
    var snoozeMinutes: Int

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case reminderID = "reminder_id"
        case iosNotificationID = "ios_notification_id"
        case remindAtISO8601 = "remind_at"
        case snoozeMinutes = "snooze_minutes"
    }
}

struct ReminderSyncResponse: Codable {
    var taskID: String?
    var reminderID: String?
    var status: String?
    var message: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case reminderID = "reminder_id"
        case status
        case message
    }
}

struct BackendTaskSummaryDTO: Decodable {
    var taskID: String
    var title: String?
    var status: String?
    var category: String?
    var currentNextStep: String?
    var lastEventPreview: String?
    var dueAtISO8601: String?
    var reminderAtISO8601: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case title
        case status
        case category
        case currentNextStep = "current_next_step"
        case lastEventPreview = "last_event_preview"
        case dueAtISO8601 = "due_at"
        case reminderAtISO8601 = "reminder_at"
    }
}

struct BackendTaskDetailDTO: Decodable {
    var taskID: String
    var title: String?
    var status: String?
    var category: String?
    var prompt: String?
    var clarification: String?
    var latestOutput: String?
    var generatedReply: String?
    var currentNextStep: String?
    var dueAtISO8601: String?
    var reminderAtISO8601: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case title
        case status
        case category
        case prompt
        case clarification
        case latestOutput = "latest_output"
        case generatedReply = "generated_reply"
        case currentNextStep = "current_next_step"
        case dueAtISO8601 = "due_at"
        case reminderAtISO8601 = "reminder_at"
    }
}

struct BackendTaskOutputDTO: Decodable {
    var outputID: String?
    var taskID: String?
    var content: String?
    var kind: String?
    var createdAtISO8601: String?

    enum CodingKeys: String, CodingKey {
        case outputID = "output_id"
        case taskID = "task_id"
        case content
        case kind
        case createdAtISO8601 = "created_at"
    }
}

struct BackendTaskEventDTO: Decodable {
    var eventID: String?
    var taskID: String?
    var title: String?
    var detail: String?
    var createdAtISO8601: String?

    enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case taskID = "task_id"
        case title
        case detail
        case createdAtISO8601 = "created_at"
    }
}

struct BackendChecklistItemDTO: Decodable {
    var itemID: String?
    var taskID: String?
    var text: String?
    var isDone: Bool?

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case taskID = "task_id"
        case text
        case isDone = "is_done"
    }
}

struct BackendReminderDTO: Decodable {
    var reminderID: String?
    var taskID: String?
    var remindAtISO8601: String?
    var iosNotificationID: String?
    var status: String?

    enum CodingKeys: String, CodingKey {
        case reminderID = "reminder_id"
        case taskID = "task_id"
        case remindAtISO8601 = "remind_at"
        case iosNotificationID = "ios_notification_id"
        case status
    }
}
