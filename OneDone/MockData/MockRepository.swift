import Foundation

enum MockRepository {
    static let cancelSubscriptionClarificationOptions: [String] = [
        "App Store",
        "Google Play",
        "Website/account",
        "PayPal",
        "Bank/card charge",
        "I'm not sure"
    ]

    static let templates: [TaskTemplate] = [
        TaskTemplate(
            title: "Follow-up email",
            promptHint: "Write a polite follow-up for yesterday's product demo. Mention one key benefit and propose two time slots.",
            focus: "Clear and professional"
        ),
        TaskTemplate(
            title: "Weekly planning",
            promptHint: "Plan my week around three priorities: launch prep, customer calls, and personal admin.",
            focus: "Balanced workload"
        ),
        TaskTemplate(
            title: "Boundary-setting reply",
            promptHint: "Draft a calm response that declines extra scope this week while offering an alternative timeline.",
            focus: "Respectful boundaries"
        )
    ]

    static let seedTasks: [MockTask] = [
        MockTask(
            title: "Client follow-up",
            prompt: "Need a concise follow-up after Monday's meeting.",
            clarification: "Should the tone be formal or friendly?",
            generatedReply: "Thanks again for Monday's discussion. I appreciate the thoughtful questions and attached a short recap. Would Thursday 11:00 or Friday 14:00 work for next steps?",
            actionPlan: [
                "Add one-sentence meeting recap",
                "Offer two concrete time slots",
                "Close with a clear next step"
            ],
            createdAt: Date().addingTimeInterval(-86_400),
            dueDate: Date().addingTimeInterval(2 * 86_400),
            status: .ready
        ),
        MockTask(
            title: "Weekly plan",
            prompt: "I feel overloaded and need a calmer weekly plan.",
            clarification: "What must be done by Friday?",
            generatedReply: "This week, prioritize launch prep in the mornings, customer calls in two focused blocks, and personal admin in one 45-minute window.",
            actionPlan: [
                "Pick top three outcomes",
                "Reserve two call blocks",
                "Protect one admin slot"
            ],
            createdAt: Date().addingTimeInterval(-3 * 86_400),
            dueDate: Date().addingTimeInterval(86_400),
            status: .inProgress
        )
    ]

    static func makeDraft(prompt: String, template: TaskTemplate?) -> TaskDraft {
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackPrompt = template?.promptHint ?? "Help me make this task clear and doable."
        let effectivePrompt = cleanPrompt.isEmpty ? fallbackPrompt : cleanPrompt

        if isCancelSubscriptionIntent(prompt: effectivePrompt, template: template) {
            return TaskDraft(
                title: "Cancel subscription",
                prompt: effectivePrompt,
                intent: .cancelSubscription,
                requiresClarification: true,
                clarificationQuestion: "Where is this subscription billed?",
                clarificationOptions: cancelSubscriptionClarificationOptions,
                generatedReply: "I need one quick detail before giving exact steps.",
                actionPlan: []
            )
        }

        let shortTitle = effectivePrompt
            .split(separator: ".")
            .first
            .map(String.init) ?? "New task"

        return TaskDraft(
            title: String(shortTitle.prefix(36)),
            prompt: effectivePrompt,
            intent: .generic,
            requiresClarification: false,
            clarificationQuestion: "",
            clarificationOptions: [],
            generatedReply: "Thanks for the context. Here's a calm first draft based on your goal, with a clear ask and one next step.",
            actionPlan: [
                "Clarify your desired outcome",
                "Draft one focused response",
                "Take one concrete next action"
            ]
        )
    }

    static func applyClarification(answer: String, to draft: TaskDraft) -> TaskDraft {
        var updated = draft
        let cleanAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.clarificationAnswer = cleanAnswer
        updated.requiresClarification = false

        if draft.intent == .cancelSubscription {
            switch cleanAnswer {
            case "App Store":
                updated.title = "Cancel App Store subscription"
                updated.generatedReply = "This is an App Store subscription. You cancel it through your Apple ID, not the service website."
                updated.actionPlan = [
                    "Open Settings on your iPhone",
                    "Tap your Apple ID/name",
                    "Tap Subscriptions",
                    "Find the subscription",
                    "Tap Cancel Subscription",
                    "Save confirmation"
                ]
            case "Google Play":
                updated.title = "Cancel Google Play subscription"
                updated.generatedReply = "This looks billed via Google Play. Cancel it from your Google account subscriptions list."
                updated.actionPlan = [
                    "Open Google Play",
                    "Tap profile",
                    "Open Payments & subscriptions",
                    "Tap Subscriptions",
                    "Select the subscription",
                    "Tap Cancel subscription"
                ]
            case "Website/account":
                updated.title = "Cancel website subscription"
                updated.generatedReply = "This looks billed through the service website. Cancel it from the account billing area."
                updated.actionPlan = [
                    "Sign in to the service account",
                    "Open billing/subscription settings",
                    "Select the active plan",
                    "Choose cancel subscription",
                    "Confirm cancellation",
                    "Save confirmation email"
                ]
            case "PayPal":
                updated.title = "Cancel PayPal payment agreement"
                updated.generatedReply = "This looks billed via PayPal. Cancel the automatic payment in your PayPal account."
                updated.actionPlan = [
                    "Open PayPal",
                    "Go to Settings",
                    "Open Payments",
                    "Find Automatic Payments",
                    "Select the merchant",
                    "Cancel agreement"
                ]
            case "Bank/card charge", "I'm not sure":
                updated.title = "Confirm subscription billing source"
                updated.generatedReply = "Before canceling, confirm where the charge comes from so we can give exact steps."
                updated.actionPlan = [
                    "Check your latest charge descriptor",
                    "Match it to App Store, Google Play, or website",
                    "Re-open this task and choose billing source"
                ]
            default:
                updated.generatedReply = "Thanks, that helps. I'll tailor the next steps based on this billing source."
            }

            return updated
        }

        if !cleanAnswer.isEmpty {
            updated.generatedReply = "Thanks, that helps. Based on your outcome (\(cleanAnswer)), here's a focused draft reply you can send now."
            updated.actionPlan = [
                "Open with a concise context line",
                "State the requested outcome directly",
                "Close with a specific follow-up"
            ]
        }

        return updated
    }

    static func makeTask(from draft: TaskDraft, status: TaskStatus = .ready) -> MockTask {
        var generatedReply = draft.generatedReply
        var actionPlan = draft.actionPlan

        if status == .needsClarification {
            generatedReply = "This task needs one clarification before OneDone can provide exact steps."
            actionPlan = [
                "Open task details",
                "Answer clarification question",
                "Continue to result"
            ]
        }

        return MockTask(
            title: draft.title.isEmpty ? "New task" : draft.title,
            prompt: draft.prompt,
            clarification: draft.clarificationAnswer.isEmpty ? draft.clarificationQuestion : draft.clarificationAnswer,
            generatedReply: generatedReply,
            actionPlan: actionPlan,
            createdAt: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            status: status
        )
    }

    private static func isCancelSubscriptionIntent(prompt: String, template: TaskTemplate?) -> Bool {
        let normalizedPrompt = normalize(prompt)
        let normalizedTemplateTitle = normalize(template?.title ?? "")
        let normalizedTemplateHint = normalize(template?.promptHint ?? "")

        let promptHasKeyword = normalizedPrompt.contains("cancel_subscription") ||
            (normalizedPrompt.contains("cancel") && normalizedPrompt.contains("subscription"))
        let templateHasKeyword =
            (normalizedTemplateTitle.contains("cancel") && normalizedTemplateTitle.contains("subscription")) ||
            normalizedTemplateTitle.contains("cancel_subscription") ||
            (normalizedTemplateHint.contains("cancel") && normalizedTemplateHint.contains("subscription"))

        return promptHasKeyword || templateHasKeyword
    }

    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
