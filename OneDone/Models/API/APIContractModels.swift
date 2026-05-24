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
    case rateLimited = "rate_limited"
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

private struct AnalyzeTaskDynamicKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private struct AnalyzeTaskLooseOption: Decodable {
    let label: String?
    let title: String?
    let value: String?
    let text: String?
    let name: String?
    let message: String?

    var resolvedText: String? {
        [label, title, value, text, name, message]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }
}

private struct AnalyzeTaskDynamicContent: Decodable {
    let summary: String?
    let message: String?
    let draftReply: String?

    enum CodingKeys: String, CodingKey {
        case summary
        case message
        case draftReply = "draft_reply"
    }

    var resolvedMessage: String? {
        [draftReply, summary, message]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }
}

private struct AnalyzeTaskTaskReference: Decodable {
    let id: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        if let id = container.decodeString(forKeys: ["id", "task_id"]) {
            self.id = id
        } else {
            self.id = nil
        }
    }
}

private extension KeyedDecodingContainer where Key == AnalyzeTaskDynamicKey {
    func decodeString(forKeys keys: [String]) -> String? {
        for rawKey in keys {
            guard let key = AnalyzeTaskDynamicKey(stringValue: rawKey), contains(key) else { continue }

            if let stringValue = (try? decodeIfPresent(String.self, forKey: key)) ?? nil {
                let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }

            if let intValue = (try? decodeIfPresent(Int.self, forKey: key)) ?? nil {
                return String(intValue)
            }
        }

        return nil
    }

    func decodeBool(forKeys keys: [String]) -> Bool? {
        for rawKey in keys {
            guard let key = AnalyzeTaskDynamicKey(stringValue: rawKey), contains(key) else { continue }

            if let boolValue = (try? decodeIfPresent(Bool.self, forKey: key)) ?? nil {
                return boolValue
            }
        }

        return nil
    }

    func decodeStringArray(forKeys keys: [String]) -> [String]? {
        for rawKey in keys {
            guard let key = AnalyzeTaskDynamicKey(stringValue: rawKey), contains(key) else { continue }

            if let values = (try? decodeIfPresent([String].self, forKey: key)) ?? nil {
                let normalized = values
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !normalized.isEmpty {
                    return normalized
                }
            }

            if let values = (try? decodeIfPresent([AnalyzeTaskLooseOption].self, forKey: key)) ?? nil {
                let normalized = values.compactMap(\.resolvedText)
                if !normalized.isEmpty {
                    return normalized
                }
            }

            if let singleValue = (try? decodeIfPresent(String.self, forKey: key)) ?? nil {
                let trimmed = singleValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return [trimmed]
                }
            }
        }

        return nil
    }

    func decodeObject<T: Decodable>(forKeys keys: [String], as type: T.Type = T.self) -> T? {
        for rawKey in keys {
            guard let key = AnalyzeTaskDynamicKey(stringValue: rawKey), contains(key) else { continue }
            if let value = (try? decodeIfPresent(type, forKey: key)) ?? nil {
                return value
            }
        }

        return nil
    }
}

struct AnalyzeTaskClarificationPayload: Decodable {
    var clarificationID: String?
    var status: String?
    var question: String?
    var helperText: String?
    var options: [String]
    var title: String?

    init(
        clarificationID: String? = nil,
        status: String? = nil,
        question: String?,
        helperText: String?,
        options: [String],
        title: String?
    ) {
        self.clarificationID = clarificationID
        self.status = status
        self.question = question
        self.helperText = helperText
        self.options = options
        self.title = title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        clarificationID = container.decodeString(forKeys: ["id", "clarification_id"])
        status = container.decodeString(forKeys: ["status"])
        question = container.decodeString(forKeys: ["question", "prompt"])
        helperText = container.decodeString(forKeys: ["helper_text", "helperText", "hint"])
        title = container.decodeString(forKeys: ["title", "heading"])
        options = container.decodeStringArray(forKeys: ["options", "choices", "answers"]) ?? []
    }
}

struct AnalyzeTaskAnalysisPayload: Decodable {
    var title: String?
    var summary: String?
    var latestOutput: String?
    var checklist: [String]
    var nextSteps: [String]
    var category: String?

    init(
        title: String?,
        summary: String?,
        latestOutput: String?,
        checklist: [String],
        nextSteps: [String],
        category: String?
    ) {
        self.title = title
        self.summary = summary
        self.latestOutput = latestOutput
        self.checklist = checklist
        self.nextSteps = nextSteps
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        title = container.decodeString(forKeys: ["title", "task_title", "heading"])
        summary = container.decodeString(forKeys: ["summary", "analysis", "message", "explanation"])
        latestOutput = container.decodeString(forKeys: ["latest_output", "latestOutput", "output"])
        checklist = container.decodeStringArray(forKeys: ["checklist", "checklist_items", "steps", "action_plan"]) ?? []
        nextSteps = container.decodeStringArray(forKeys: ["next_steps", "nextSteps", "recommended_steps", "action_steps"]) ?? []

        if nextSteps.isEmpty,
           let nextStep = container.decodeString(forKeys: ["next_step"]) {
            nextSteps = [nextStep]
        }

        if nextSteps.isEmpty,
           let currentNextStep = container.decodeString(forKeys: ["current_next_step", "currentNextStep"]) {
            nextSteps = [currentNextStep]
        }

        category = container.decodeString(forKeys: ["category", "intent"])
    }
}

struct AnalyzeTaskSplitPreviewItem: Decodable {
    var id: String?
    var title: String

    init(id: String?, title: String) {
        self.id = id
        self.title = title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)
        id = container.decodeString(forKeys: ["id", "task_id"])
        title = container.decodeString(forKeys: ["title", "name", "label", "summary"]) ?? "Task"
    }
}

struct AnalyzeTaskSplitPreviewPayload: Decodable {
    var title: String?
    var message: String?
    var items: [AnalyzeTaskSplitPreviewItem]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)
        title = container.decodeString(forKeys: ["title", "heading"])
        message = container.decodeString(forKeys: ["message", "summary"])
        items = container.decodeObject(forKeys: ["items", "tasks", "suggested_tasks"]) ?? []

        if items.isEmpty,
           let fallbackItems = container.decodeStringArray(forKeys: ["items", "tasks", "suggested_tasks"]) {
            items = fallbackItems.map { AnalyzeTaskSplitPreviewItem(id: nil, title: $0) }
        }
    }

    init(title: String?, message: String?, items: [AnalyzeTaskSplitPreviewItem]) {
        self.title = title
        self.message = message
        self.items = items
    }
}

struct AnalyzeTaskErrorPayload: Decodable {
    var code: String?
    var message: String?
    var retryable: Bool?

    init(from decoder: Decoder) throws {
        if let singleContainer = try? decoder.singleValueContainer(),
           let message = try? singleContainer.decode(String.self) {
            code = nil
            self.message = message
            retryable = nil
            return
        }

        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)
        code = container.decodeString(forKeys: ["code", "error_code"])
        message = container.decodeString(forKeys: ["message", "error_description", "detail", "error"])
        retryable = container.decodeBool(forKeys: ["retryable"])
    }

    init(code: String?, message: String?, retryable: Bool?) {
        self.code = code
        self.message = message
        self.retryable = retryable
    }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        taskID = container.decodeString(forKeys: ["task_id", "taskId", "id"])
        if taskID == nil {
            let taskReference: AnalyzeTaskTaskReference? = container.decodeObject(forKeys: ["task", "task_ref", "life_task"])
            taskID = taskReference?.id
        }

        let responseTypeRaw = container.decodeString(forKeys: ["response_type", "responseType", "type"])
        responseType = AnalyzeTaskResponseType(rawValue: responseTypeRaw ?? "") ?? .unknown

        clarification = container.decodeObject(forKeys: ["clarification", "clarification_payload"])
        taskAnalysis = container.decodeObject(forKeys: ["task_analysis", "analysis"])
        multiTaskSplitPreview = container.decodeObject(forKeys: ["multi_task_split_preview", "split_preview"])
        access = container.decodeObject(forKeys: ["access"])

        if var clarification,
           clarification.clarificationID == nil {
            clarification.clarificationID = container.decodeString(forKeys: ["clarification_id"])
            clarification.status = clarification.status ?? container.decodeString(forKeys: ["status"])
            self.clarification = clarification
        }

        let explicitError: AnalyzeTaskErrorPayload? = container.decodeObject(forKeys: ["error"])
        let inferredErrorCode = container.decodeString(forKeys: ["error_code"])
        let inferredErrorMessage = container.decodeString(forKeys: ["error_message", "error_description", "detail"])
        let inferredRetryable = container.decodeBool(forKeys: ["retryable"])
        error = explicitError ?? {
            if inferredErrorCode != nil || inferredErrorMessage != nil {
                return AnalyzeTaskErrorPayload(
                    code: inferredErrorCode,
                    message: inferredErrorMessage,
                    retryable: inferredRetryable
                )
            }
            return nil
        }()

        message = container.decodeString(forKeys: ["message", "detail", "status_message"]) ?? error?.message

        if clarification == nil {
            let inferredClarification = AnalyzeTaskClarificationPayload(
                clarificationID: container.decodeString(forKeys: ["clarification_id", "id"]),
                status: container.decodeString(forKeys: ["status"]),
                question: container.decodeString(forKeys: ["question", "clarification_question"]),
                helperText: container.decodeString(forKeys: ["helper_text", "clarification_helper_text"]),
                options: container.decodeStringArray(forKeys: ["options", "clarification_options"]) ?? [],
                title: container.decodeString(forKeys: ["title", "clarification_title"])
            )

            if inferredClarification.question != nil || !inferredClarification.options.isEmpty {
                clarification = inferredClarification
            }
        }

        if taskAnalysis == nil {
            let inferredAnalysis = AnalyzeTaskAnalysisPayload(
                title: container.decodeString(forKeys: ["title", "task_title"]),
                summary: container.decodeString(forKeys: ["summary", "analysis", "latest_output", "message"]),
                latestOutput: container.decodeString(forKeys: ["latest_output"]),
                checklist: container.decodeStringArray(forKeys: ["checklist", "checklist_items", "steps"]) ?? [],
                nextSteps: container.decodeStringArray(forKeys: ["next_steps", "action_steps"]) ?? [],
                category: container.decodeString(forKeys: ["category"])
            )

            if inferredAnalysis.summary != nil ||
                inferredAnalysis.latestOutput != nil ||
                !inferredAnalysis.checklist.isEmpty ||
                !inferredAnalysis.nextSteps.isEmpty {
                taskAnalysis = inferredAnalysis
            }
        }

        if multiTaskSplitPreview == nil,
           let splitItems = container.decodeStringArray(forKeys: ["split_items", "tasks", "suggested_tasks"]) {
            let mappedItems = splitItems.map { AnalyzeTaskSplitPreviewItem(id: nil, title: $0) }
            multiTaskSplitPreview = AnalyzeTaskSplitPreviewPayload(
                title: container.decodeString(forKeys: ["title"]),
                message: container.decodeString(forKeys: ["message"]),
                items: mappedItems
            )
        }

        if responseType == .unknown {
            if clarification != nil {
                responseType = .clarification
            } else if taskAnalysis != nil {
                responseType = .taskAnalysis
            } else if multiTaskSplitPreview != nil {
                responseType = .multiTaskSplitPreview
            } else if error?.code == "rate_limited" {
                responseType = .rateLimited
            }
        }
    }

    init(
        taskID: String?,
        responseType: AnalyzeTaskResponseType,
        clarification: AnalyzeTaskClarificationPayload?,
        taskAnalysis: AnalyzeTaskAnalysisPayload?,
        multiTaskSplitPreview: AnalyzeTaskSplitPreviewPayload?,
        error: AnalyzeTaskErrorPayload?,
        message: String?,
        access: APIAccessStatePayload?
    ) {
        self.taskID = taskID
        self.responseType = responseType
        self.clarification = clarification
        self.taskAnalysis = taskAnalysis
        self.multiTaskSplitPreview = multiTaskSplitPreview
        self.error = error
        self.message = message
        self.access = access
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
    var clarificationID: String
    var answerText: String
    var billingSource: String?

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case clarificationID = "clarification_id"
        case answerText = "answer_text"
        case billingSource = "billing_source"
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

struct GenerateReplyResponse: Decodable {
    var taskID: String
    var subject: String?
    var message: String

    init(taskID: String, subject: String?, message: String) {
        self.taskID = taskID
        self.subject = subject
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        guard let resolvedTaskID = container.decodeString(forKeys: ["task_id", "id"]) else {
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing task_id/id for GenerateReplyResponse"
                )
            )
        }

        let resolvedMessage = container.decodeString(forKeys: ["message", "draft_reply"])
        if resolvedMessage == nil,
           let contentObject = container.decodeObject(forKeys: ["content"], as: AnalyzeTaskDynamicContent.self) {
            taskID = resolvedTaskID
            subject = container.decodeString(forKeys: ["subject"])
            message = contentObject.resolvedMessage ?? "Reply generated."
            return
        }

        guard let resolvedMessage else {
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing draft reply message"
                )
            )
        }

        taskID = resolvedTaskID
        subject = container.decodeString(forKeys: ["subject"])
        message = resolvedMessage
    }
}

struct ValidateSubscriptionRequest: Codable {
    var transactionID: String
    var originalTransactionID: String?
    var productID: String?
    var verificationMode: String?
    var purchasedAtISO8601: String?
    var expiresAtISO8601: String?
    var ownershipType: String?
    var revocationDateISO8601: String?
    var entitlementStatus: String?
    var storeKitStatus: String?
    var source: String?
    var platform: String?
    var environment: String?
    var storefront: String?

    enum CodingKeys: String, CodingKey {
        case transactionID = "transaction_id"
        case originalTransactionID = "original_transaction_id"
        case productID = "product_id"
        case verificationMode = "verification_mode"
        case purchasedAtISO8601 = "purchased_at"
        case expiresAtISO8601 = "expires_at"
        case ownershipType = "ownership_type"
        case revocationDateISO8601 = "revocation_date"
        case entitlementStatus = "entitlement_status"
        case storeKitStatus = "storekit_status"
        case source
        case platform
        case environment
        case storefront
    }
}

struct ValidateSubscriptionResponse: Decodable {
    var access: APIAccessStatePayload

    enum CodingKeys: String, CodingKey {
        case access
    }

    init(access: APIAccessStatePayload) {
        self.access = access
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

struct RestorePurchasesRequest: Codable {
    var entitlements: [RestorePurchaseEntitlement]?

    enum CodingKeys: String, CodingKey {
        case entitlements
    }
}

struct RestorePurchaseEntitlement: Codable {
    var transactionID: String
    var originalTransactionID: String?
    var productID: String?
    var verificationMode: String?
    var purchasedAtISO8601: String?
    var expiresAtISO8601: String?
    var ownershipType: String?
    var revocationDateISO8601: String?
    var entitlementStatus: String?
    var storeKitStatus: String?
    var source: String?
    var platform: String?
    var environment: String?
    var storefront: String?

    enum CodingKeys: String, CodingKey {
        case transactionID = "transaction_id"
        case originalTransactionID = "original_transaction_id"
        case productID = "product_id"
        case verificationMode = "verification_mode"
        case purchasedAtISO8601 = "purchased_at"
        case expiresAtISO8601 = "expires_at"
        case ownershipType = "ownership_type"
        case revocationDateISO8601 = "revocation_date"
        case entitlementStatus = "entitlement_status"
        case storeKitStatus = "storekit_status"
        case source
        case platform
        case environment
        case storefront
    }
}

struct RestorePurchasesResponse: Decodable {
    var access: APIAccessStatePayload

    enum CodingKeys: String, CodingKey {
        case access
    }

    init(access: APIAccessStatePayload) {
        self.access = access
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

struct MessageMarkedSentRequest: Codable {
    var taskID: String
    var sentAtISO8601: String

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case sentAtISO8601 = "sent_at"
    }
}

struct MessageMarkedSentResponse: Decodable {
    var taskID: String
    var status: String
    var message: String?

    init(taskID: String, status: String, message: String?) {
        self.taskID = taskID
        self.status = status
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        guard let resolvedTaskID = container.decodeString(forKeys: ["task_id", "id"]) else {
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing task_id/id for MessageMarkedSentResponse"
                )
            )
        }

        taskID = resolvedTaskID
        status = container.decodeString(forKeys: ["status"]) ?? "waiting_for_reply"
        message = container.decodeString(forKeys: ["message", "event_message"])
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
    var reminderID: String
    var remindAtISO8601: String?
    var iosNotificationID: String?
    var localNotificationStatus: String?

    enum CodingKeys: String, CodingKey {
        case reminderID = "reminder_id"
        case remindAtISO8601 = "remind_at"
        case iosNotificationID = "ios_notification_id"
        case localNotificationStatus = "local_notification_status"
    }
}

struct ReminderCancelRequest: Codable {
    var reminderID: String

    enum CodingKeys: String, CodingKey {
        case reminderID = "reminder_id"
    }
}

struct ReminderSnoozeRequest: Codable {
    var reminderID: String
    var snoozeUntilISO8601: String
    var iosNotificationID: String?
    var localNotificationStatus: String?

    enum CodingKeys: String, CodingKey {
        case reminderID = "reminder_id"
        case snoozeUntilISO8601 = "snooze_until"
        case iosNotificationID = "ios_notification_id"
        case localNotificationStatus = "local_notification_status"
    }
}

struct ReminderSyncResponse: Decodable {
    var taskID: String?
    var reminderID: String?
    var status: String?
    var message: String?

    init(taskID: String?, reminderID: String?, status: String?, message: String?) {
        self.taskID = taskID
        self.reminderID = reminderID
        self.status = status
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        taskID = container.decodeString(forKeys: ["task_id"])
        reminderID = container.decodeString(forKeys: ["reminder_id", "id"])
        status = container.decodeString(forKeys: ["status"])
        message = container.decodeString(forKeys: ["message", "event_message"])

        if let reminderObject = container.decodeObject(forKeys: ["reminder"], as: BackendReminderDTO.self) {
            if reminderID == nil {
                reminderID = reminderObject.reminderID
            }
            if taskID == nil {
                taskID = reminderObject.taskID
            }
            if status == nil {
                status = reminderObject.status
            }
        }
    }
}

struct BackendTaskSummaryDTO: Decodable {
    var taskID: String
    var title: String?
    var status: String?
    var category: String?
    var createdAtISO8601: String?
    var currentNextStep: String?
    var lastEventPreview: String?
    var dueAtISO8601: String?
    var reminderAtISO8601: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        guard let resolvedTaskID = container.decodeString(forKeys: ["task_id", "id"]) else {
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing task_id/id for BackendTaskSummaryDTO"
                )
            )
        }

        taskID = resolvedTaskID
        title = container.decodeString(forKeys: ["title", "task_title"])
        status = container.decodeString(forKeys: ["status"])
        category = container.decodeString(forKeys: ["category"])
        createdAtISO8601 = container.decodeString(forKeys: ["created_at"])
        currentNextStep = container.decodeString(forKeys: ["current_next_step", "currentNextStep"])
        lastEventPreview = container.decodeString(forKeys: ["last_event_preview", "event_message"])
        dueAtISO8601 = container.decodeString(forKeys: ["due_at"])
        reminderAtISO8601 = container.decodeString(forKeys: ["reminder_at", "remind_at"])
    }
}

struct BackendTaskDetailDTO: Decodable {
    var taskID: String
    var title: String?
    var status: String?
    var category: String?
    var createdAtISO8601: String?
    var prompt: String?
    var clarification: String?
    var latestOutput: String?
    var generatedReply: String?
    var currentNextStep: String?
    var dueAtISO8601: String?
    var reminderAtISO8601: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        guard let resolvedTaskID = container.decodeString(forKeys: ["task_id", "id"]) else {
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing task_id/id for BackendTaskDetailDTO"
                )
            )
        }

        taskID = resolvedTaskID
        title = container.decodeString(forKeys: ["title", "task_title"])
        status = container.decodeString(forKeys: ["status"])
        category = container.decodeString(forKeys: ["category"])
        createdAtISO8601 = container.decodeString(forKeys: ["created_at"])
        prompt = container.decodeString(forKeys: ["prompt", "description"])
        clarification = container.decodeString(forKeys: ["clarification"])
        latestOutput = container.decodeString(forKeys: ["latest_output", "output", "current_output"])
        generatedReply = container.decodeString(forKeys: ["generated_reply", "reply_draft"])
        currentNextStep = container.decodeString(forKeys: ["current_next_step", "currentNextStep"])
        dueAtISO8601 = container.decodeString(forKeys: ["due_at"])
        reminderAtISO8601 = container.decodeString(forKeys: ["reminder_at", "remind_at"])
    }
}

struct BackendTaskOutputDTO: Decodable {
    var outputID: String?
    var taskID: String?
    var content: String?
    var kind: String?
    var createdAtISO8601: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        outputID = container.decodeString(forKeys: ["output_id", "id"])
        taskID = container.decodeString(forKeys: ["task_id"])
        content = container.decodeString(forKeys: ["content"])
        kind = container.decodeString(forKeys: ["kind", "output_type"])
        createdAtISO8601 = container.decodeString(forKeys: ["created_at"])
    }
}

struct BackendTaskEventDTO: Decodable {
    var eventID: String?
    var taskID: String?
    var title: String?
    var detail: String?
    var createdAtISO8601: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        eventID = container.decodeString(forKeys: ["event_id", "id"])
        taskID = container.decodeString(forKeys: ["task_id"])
        title = container.decodeString(forKeys: ["title", "event_type"])
        detail = container.decodeString(forKeys: ["detail", "event_message"])
        createdAtISO8601 = container.decodeString(forKeys: ["created_at"])
    }
}

struct BackendChecklistItemDTO: Decodable {
    var itemID: String?
    var taskID: String?
    var text: String?
    var isDone: Bool?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        itemID = container.decodeString(forKeys: ["item_id", "id"])
        taskID = container.decodeString(forKeys: ["task_id"])
        text = container.decodeString(forKeys: ["text", "content"])

        if let explicit = container.decodeBool(forKeys: ["is_done"]) {
            isDone = explicit
        } else if let status = container.decodeString(forKeys: ["status"]) {
            isDone = status.lowercased() == "done"
        } else {
            isDone = nil
        }
    }
}

struct BackendReminderDTO: Decodable {
    var reminderID: String?
    var taskID: String?
    var remindAtISO8601: String?
    var iosNotificationID: String?
    var status: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnalyzeTaskDynamicKey.self)

        reminderID = container.decodeString(forKeys: ["reminder_id", "id"])
        taskID = container.decodeString(forKeys: ["task_id"])
        remindAtISO8601 = container.decodeString(forKeys: ["remind_at"])
        iosNotificationID = container.decodeString(forKeys: ["ios_notification_id"])
        status = container.decodeString(forKeys: ["status"])
    }
}
