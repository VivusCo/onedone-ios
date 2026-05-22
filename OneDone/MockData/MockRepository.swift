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
            title: "Cancel a subscription",
            promptHint: "Help me cancel this subscription and ask for written confirmation that billing will stop.",
            focus: "Clear cancellation steps",
            backendTemplateID: "cancel_subscription"
        ),
        TaskTemplate(
            title: "Return an item",
            promptHint: "Write a return request for this purchase, including order details and preferred resolution.",
            focus: "Simple return request",
            backendTemplateID: "return_item"
        ),
        TaskTemplate(
            title: "Request a refund",
            promptHint: "Draft a polite refund request with clear facts and a direct ask.",
            focus: "Calm refund message",
            backendTemplateID: "request_refund"
        ),
        TaskTemplate(
            title: "Understand a bill",
            promptHint: "Paste the bill text and help me understand each charge in plain language.",
            focus: "Paste the bill text",
            backendTemplateID: "understand_bill"
        ),
        TaskTemplate(
            title: "Write a complaint",
            promptHint: "Draft a respectful complaint that states the issue, impact, and requested fix.",
            focus: "Firm but respectful tone",
            backendTemplateID: "write_complaint"
        ),
        TaskTemplate(
            title: "Reply to a message",
            promptHint: "Paste the message text and draft a concise reply with one clear next step.",
            focus: "Clear next step",
            backendTemplateID: "reply_to_message"
        )
    ]

    static let seedTasks: [MockTask] = [
        MockTask(
            title: "Cancel photo storage subscription",
            category: "Subscription",
            prompt: "I canceled this subscription but still got charged this month.",
            clarification: "Billed through App Store",
            generatedReply: "The cancellation looks submitted. Confirm the subscription status and save proof in case support is needed.",
            actionPlan: [
                "Open your Subscriptions list and confirm status is Canceled",
                "Take a screenshot of cancellation details",
                "Set a reminder to verify no new charge appears next cycle"
            ],
            createdAt: Date().addingTimeInterval(-2 * 86_400),
            dueDate: Date().addingTimeInterval(86_400),
            status: .followUpNeeded,
            latestAIOutput: "Cancellation route confirmed via Apple ID. Preserve proof and verify the next billing cycle.",
            replyDraft: "Hi, I already canceled this subscription in Apple settings. Please confirm no further billing will occur and reverse this latest charge if possible.",
            currentNextStep: "Confirm the status shows Canceled in your Apple subscriptions.",
            lastEventPreview: "Support asked for cancellation proof.",
            reminderDate: Date().addingTimeInterval(10 * 3_600),
            timeline: [
                TaskTimelineEntry(
                    title: "Task analyzed",
                    detail: "OneDone identified this as an App Store billing flow.",
                    date: Date().addingTimeInterval(-2 * 86_400)
                ),
                TaskTimelineEntry(
                    title: "Support contacted",
                    detail: "You sent a cancellation confirmation request.",
                    date: Date().addingTimeInterval(-28 * 3_600)
                ),
                TaskTimelineEntry(
                    title: "Awaiting proof capture",
                    detail: "Save cancellation evidence before next billing date.",
                    date: Date().addingTimeInterval(-6 * 3_600)
                )
            ]
        ),
        MockTask(
            title: "Dispute duplicate bank charge",
            category: "Billing",
            prompt: "I was charged twice for the same grocery order.",
            clarification: "Bank/card charge",
            generatedReply: "You can dispute this quickly with your bank by sharing both transaction IDs and order details.",
            actionPlan: [
                "Capture both charge timestamps from your statement",
                "Submit dispute form with order receipt",
                "Set follow-up reminder for bank response window"
            ],
            createdAt: Date().addingTimeInterval(-86_400),
            dueDate: Date().addingTimeInterval(12 * 3_600),
            status: .dueSoon,
            latestAIOutput: "Escalate as a duplicate card charge and request temporary credit while reviewed.",
            currentNextStep: "Submit the bank dispute before tomorrow morning.",
            lastEventPreview: "Reminder window closes in 12 hours.",
            reminderDate: Date().addingTimeInterval(3 * 3_600),
            timeline: [
                TaskTimelineEntry(
                    title: "Task analyzed",
                    detail: "Classified as duplicate card charge dispute.",
                    date: Date().addingTimeInterval(-86_400)
                ),
                TaskTimelineEntry(
                    title: "Documents prepared",
                    detail: "Order receipt and statement lines collected.",
                    date: Date().addingTimeInterval(-20 * 3_600)
                )
            ]
        ),
        MockTask(
            title: "Streaming plan cancellation",
            category: "Subscription",
            prompt: "Cancel my streaming plan and make sure auto-renew is off.",
            clarification: "Where is this subscription billed?",
            generatedReply: "This task needs one clarification before exact cancel steps can be provided.",
            actionPlan: [
                "Open task details",
                "Answer billing source",
                "Continue to cancellation steps"
            ],
            createdAt: Date().addingTimeInterval(-11 * 3_600),
            dueDate: Date().addingTimeInterval(2 * 86_400),
            status: .needsClarification,
            latestAIOutput: "Billing source is required before giving reliable cancellation instructions.",
            currentNextStep: "Answer where this subscription is billed.",
            lastEventPreview: "Clarification is still pending.",
            timeline: [
                TaskTimelineEntry(
                    title: "Task created",
                    detail: "Cancellation request submitted.",
                    date: Date().addingTimeInterval(-11 * 3_600)
                ),
                TaskTimelineEntry(
                    title: "Needs clarification",
                    detail: "Waiting for billing source selection.",
                    date: Date().addingTimeInterval(-10 * 3_600)
                )
            ]
        ),
        MockTask(
            title: "Landlord maintenance follow-up",
            category: "Housing",
            prompt: "Need a follow-up message for unresolved leak repair.",
            clarification: "Friendly but firm tone",
            generatedReply: "Here's a concise follow-up asking for a confirmed repair date and acknowledging prior requests.",
            actionPlan: [
                "Send follow-up message",
                "Wait for landlord reply window",
                "Escalate if no response after 48 hours"
            ],
            createdAt: Date().addingTimeInterval(-4 * 86_400),
            dueDate: Date().addingTimeInterval(3 * 86_400),
            status: .waitingForReply,
            latestAIOutput: "Reply draft prepared with a specific deadline request.",
            replyDraft: "Hi, following up on the leak request from earlier this week. Could you confirm the repair date by tomorrow afternoon?",
            currentNextStep: "Wait for landlord reply by tomorrow afternoon.",
            lastEventPreview: "Message sent, awaiting response.",
            reminderDate: Date().addingTimeInterval(30 * 3_600),
            timeline: [
                TaskTimelineEntry(
                    title: "Draft generated",
                    detail: "OneDone prepared a calm follow-up.",
                    date: Date().addingTimeInterval(-4 * 86_400)
                ),
                TaskTimelineEntry(
                    title: "Follow-up sent",
                    detail: "Message delivered to landlord.",
                    date: Date().addingTimeInterval(-20 * 3_600)
                )
            ]
        ),
        MockTask(
            title: "Insurance document summary",
            category: "Admin",
            prompt: "Need to share proof of address details for a policy update.",
            clarification: "Paste key text from the latest utility bill",
            generatedReply: "Summarize the document text clearly, then share it in the insurer message form and save confirmation.",
            actionPlan: [
                "Paste key address details into a clean note",
                "Share the summary in insurer message form",
                "Save submission confirmation"
            ],
            createdAt: Date().addingTimeInterval(-2 * 86_400),
            dueDate: Date().addingTimeInterval(4 * 86_400),
            status: .inProgress
        ),
        MockTask(
            title: "Gym contract question",
            category: "Subscription",
            prompt: "Ask if I can pause my gym membership for two months.",
            clarification: "Contract starts next month",
            generatedReply: "A short member-services message is ready so you can ask for a temporary pause.",
            actionPlan: [
                "Send pause request to member services",
                "Ask for written confirmation",
                "Set follow-up reminder in 2 days"
            ],
            createdAt: Date().addingTimeInterval(-7 * 3_600),
            dueDate: Date().addingTimeInterval(3 * 86_400),
            status: .ready,
            latestAIOutput: "Draft is ready to send with specific pause dates and confirmation request.",
            replyDraft: "Hi team, I'd like to request a temporary pause from July 1 through August 31. Please confirm eligibility and any fees.",
            currentNextStep: "Send the prepared pause request.",
            lastEventPreview: "Draft completed and ready."
        ),
        MockTask(
            title: "Move utilities to next month",
            category: "Finance",
            prompt: "Request payment date shift for utility bill.",
            clarification: "One-time adjustment request",
            generatedReply: "Draft asks for one-time due-date extension and includes account details.",
            actionPlan: [
                "Call utility support",
                "Request due date shift",
                "Save case reference"
            ],
            createdAt: Date().addingTimeInterval(-5 * 86_400),
            dueDate: Date().addingTimeInterval(7 * 86_400),
            status: .postponed,
            latestAIOutput: "Task is postponed until next paycheck date."
        ),
        MockTask(
            title: "Return order #3921",
            category: "Shopping",
            prompt: "Request return shipping label for damaged package.",
            clarification: "Photos already sent",
            generatedReply: "Return label was issued and pickup date was confirmed.",
            actionPlan: [
                "Pack returned item",
                "Attach provided label",
                "Drop off before deadline"
            ],
            createdAt: Date().addingTimeInterval(-9 * 86_400),
            dueDate: Date().addingTimeInterval(-2 * 86_400),
            status: .done,
            latestAIOutput: "Return workflow completed and confirmation archived.",
            currentNextStep: "No action needed.",
            lastEventPreview: "Refund posted successfully.",
            timeline: [
                TaskTimelineEntry(
                    title: "Return initiated",
                    detail: "Merchant provided return instructions.",
                    date: Date().addingTimeInterval(-8 * 86_400)
                ),
                TaskTimelineEntry(
                    title: "Package dropped off",
                    detail: "Carrier accepted the return parcel.",
                    date: Date().addingTimeInterval(-6 * 86_400)
                ),
                TaskTimelineEntry(
                    title: "Refund received",
                    detail: "Charge reversal confirmed on card statement.",
                    date: Date().addingTimeInterval(-2 * 86_400)
                )
            ]
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
        let now = Date()
        var generatedReply = draft.generatedReply
        var actionPlan = draft.actionPlan
        var timeline: [TaskTimelineEntry] = [
            TaskTimelineEntry(
                title: "Task created",
                detail: "Task was added from the New Task flow.",
                date: now
            )
        ]

        if status == .needsClarification {
            generatedReply = "This task needs one clarification before OneDone can provide exact steps."
            actionPlan = [
                "Open task details",
                "Answer clarification question",
                "Continue to result"
            ]
            timeline.append(
                TaskTimelineEntry(
                    title: "Needs clarification",
                    detail: "Waiting for one detail before next steps can be generated.",
                    date: now.addingTimeInterval(60)
                )
            )
        } else {
            timeline.append(
                TaskTimelineEntry(
                    title: "Analysis complete",
                    detail: "OneDone generated a calm next-step plan.",
                    date: now.addingTimeInterval(60)
                )
            )
        }

        let category = draft.intent == .cancelSubscription ? "Subscription" : "General"
        let nextStep = actionPlan.first ?? "Review the task and continue."
        let lastEventPreview = timeline.last?.title ?? "Task created"
        let reminderDate = Calendar.current.date(byAdding: .hour, value: 12, to: now)
        let replyDraft = status == .needsClarification ? nil : draft.generatedReply

        return MockTask(
            backendTaskID: draft.backendTaskID,
            title: draft.title.isEmpty ? "New task" : draft.title,
            category: category,
            prompt: draft.prompt,
            clarification: draft.clarificationAnswer.isEmpty ? draft.clarificationQuestion : draft.clarificationAnswer,
            generatedReply: generatedReply,
            actionPlan: actionPlan,
            createdAt: now,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now),
            status: status,
            latestAIOutput: generatedReply,
            replyDraft: replyDraft,
            currentNextStep: nextStep,
            lastEventPreview: lastEventPreview,
            reminderDate: reminderDate,
            timeline: timeline
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
