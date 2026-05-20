import Foundation

enum MockRepository {
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
        let shortTitle = effectivePrompt
            .split(separator: ".")
            .first
            .map(String.init) ?? "New task"

        return TaskDraft(
            title: String(shortTitle.prefix(36)),
            prompt: effectivePrompt,
            clarificationQuestion: "What outcome should feel complete by end of day?",
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

    static func makeTask(from draft: TaskDraft) -> MockTask {
        MockTask(
            title: draft.title.isEmpty ? "New task" : draft.title,
            prompt: draft.prompt,
            clarification: draft.clarificationAnswer.isEmpty ? draft.clarificationQuestion : draft.clarificationAnswer,
            generatedReply: draft.generatedReply,
            actionPlan: draft.actionPlan,
            createdAt: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            status: .ready
        )
    }
}
