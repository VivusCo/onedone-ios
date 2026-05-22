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

struct AnalyzeTaskRequest: Codable {
    var inputText: String
    var templateKey: String?
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
}

struct AnswerClarificationResponse: Codable {
    var taskID: String
    var nextStepSummary: String
}

struct GenerateReplyRequest: Codable {
    var taskID: String
    var tone: String?
    var language: String?
}

struct GenerateReplyResponse: Codable {
    var taskID: String
    var subject: String?
    var message: String
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
}

struct MessageMarkedSentResponse: Codable {
    var taskID: String
    var status: String
}

struct ProcessIncomingReplyRequest: Codable {
    var taskID: String
    var replyText: String
}

struct ProcessIncomingReplyResponse: Codable {
    var taskID: String
    var status: String
}
