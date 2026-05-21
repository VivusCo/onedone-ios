import SwiftUI
import Observation

struct TaskDetailView: View {
    @Bindable var appState: AppState
    let taskID: UUID

    @State private var reminderFeedback: ReminderActionFeedback?
    @State private var isReminderActionInProgress: Bool = false
    @State private var showCustomDatePicker: Bool = false
    @State private var customReminderDate: Date =
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)

    private var task: MockTask? {
        appState.task(for: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Task Detail",
                    subtitle: "Keep momentum with clear next steps"
                )

                if let task {
                    headerSection(task)
                    statusSection(task)
                    nextStepSection(task)
                    checklistSection(task)
                    latestOutputSection(task)

                    if let replyDraft = task.replyDraft, !replyDraft.isEmpty {
                        replyDraftSection(task, replyDraft: replyDraft)
                    }

                    reminderSection(task)
                    timelineSection(task)
                } else {
                    ODCard {
                        Text("Task no longer exists in mock state.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .sheet(isPresented: $showCustomDatePicker) {
            customDateSheet
        }
    }

    private func headerSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Header")

                Text(task.title)
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                Text(task.category)
                    .font(OneDoneStyle.captionFont.weight(.medium))
                    .foregroundStyle(ODColor.textMuted)

                Text("Created \(dateTimeFormatter.string(from: task.createdAt))")
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    private func statusSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Status")

                HStack {
                    ODStatusBadge(title: task.status.displayTitle, tone: tone(for: task.status))
                    Spacer()
                    if let dateLabel = dueOrReminderText(task) {
                        Text(dateLabel)
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }
            }
        }
    }

    private func nextStepSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Current next step")
                Text(task.currentNextStep)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    private func checklistSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Checklist")

                if task.actionPlan.isEmpty {
                    Text("No checklist items yet.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    ForEach(Array(task.actionPlan.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.primary)
                                .padding(.top, 2)
                            Text(step)
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func latestOutputSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Latest AI output")
                Text(task.latestAIOutput)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func replyDraftSection(_ task: MockTask, replyDraft: String) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Reply draft")
                Text(replyDraft)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)

                NavigationLink {
                    DraftReplyView(appState: appState, taskID: task.id)
                } label: {
                    Text("Open Draft Reply")
                        .font(OneDoneStyle.captionFont.weight(.semibold))
                        .foregroundStyle(ODColor.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(ODColor.primarySoft)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reminderSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Reminder")

                if let reminderDate = task.reminderDate {
                    Label("Reminder set for \(dateTimeFormatter.string(from: reminderDate))", systemImage: "bell")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else if let dueDate = task.dueDate {
                    Label("Due on \(dateTimeFormatter.string(from: dueDate))", systemImage: "calendar")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    Text("No reminder set yet.")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                }

                if task.reminderDate == nil {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ODSecondaryButton(
                            title: "Tomorrow",
                            icon: "sun.max",
                            isDisabled: isReminderActionInProgress
                        ) {
                            scheduleReminder(task, afterDays: 1, context: "Reminder scheduled for tomorrow.")
                        }

                        ODSecondaryButton(
                            title: "In 2 days",
                            icon: "calendar.badge.plus",
                            isDisabled: isReminderActionInProgress
                        ) {
                            scheduleReminder(task, afterDays: 2, context: "Reminder scheduled for 2 days from now.")
                        }

                        ODSecondaryButton(
                            title: "In 3 days",
                            icon: "calendar.badge.plus",
                            isDisabled: isReminderActionInProgress
                        ) {
                            scheduleReminder(task, afterDays: 3, context: "Reminder scheduled for 3 days from now.")
                        }

                        ODSecondaryButton(
                            title: "Choose date",
                            icon: "calendar",
                            isDisabled: isReminderActionInProgress
                        ) {
                            customReminderDate = max(Date().addingTimeInterval(86_400), Date())
                            showCustomDatePicker = true
                        }
                    }
                } else {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ODSecondaryButton(
                            title: "Reschedule",
                            icon: "calendar.badge.clock",
                            isDisabled: isReminderActionInProgress
                        ) {
                            customReminderDate = max(task.reminderDate ?? Date().addingTimeInterval(86_400), Date())
                            showCustomDatePicker = true
                        }

                        ODSecondaryButton(
                            title: "Snooze +1 hour",
                            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            isDisabled: isReminderActionInProgress
                        ) {
                            runReminderAction {
                                await appState.snoozeTaskReminder(task.id, byHours: 1)
                            }
                        }

                        ODSecondaryButton(
                            title: "Cancel reminder",
                            icon: "bell.slash",
                            isDisabled: isReminderActionInProgress
                        ) {
                            runReminderAction {
                                await appState.cancelTaskReminder(task.id)
                            }
                        }
                    }
                }

                if let reminderFeedback {
                    ODInfoBanner(
                        title: reminderFeedbackTitle(reminderFeedback),
                        message: reminderFeedback.message,
                        icon: reminderFeedbackIcon(reminderFeedback),
                        tone: reminderFeedbackTone(reminderFeedback)
                    )
                }
            }
        }
    }

    private func timelineSection(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Timeline")

                if compactTimeline(for: task).isEmpty {
                    Text("No timeline events yet.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    ForEach(compactTimeline(for: task)) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(entry.title)
                                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                                    .foregroundStyle(ODColor.textPrimary)
                                Spacer()
                                Text(dateFormatter.string(from: entry.date))
                                    .font(OneDoneStyle.captionFont)
                                    .foregroundStyle(ODColor.textMuted)
                            }
                            Text(entry.detail)
                                .font(OneDoneStyle.captionFont)
                                .foregroundStyle(ODColor.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private func compactTimeline(for task: MockTask) -> [TaskTimelineEntry] {
        task.timeline
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    private func dueOrReminderText(_ task: MockTask) -> String? {
        if let reminderDate = task.reminderDate {
            return "Reminder \(dateFormatter.string(from: reminderDate))"
        }
        if let dueDate = task.dueDate {
            return "Due \(dateFormatter.string(from: dueDate))"
        }
        return nil
    }

    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(OneDoneStyle.captionFont.weight(.semibold))
            .foregroundStyle(ODColor.primary)
    }

    private var customDateSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Choose reminder date",
                    subtitle: "Pick when OneDone should remind you"
                )

                DatePicker(
                    "Reminder date",
                    selection: $customReminderDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(ODColor.primary)

                ODPrimaryButton(
                    title: "Schedule reminder",
                    icon: "checkmark.circle.fill",
                    isDisabled: isReminderActionInProgress
                ) {
                    guard let task else { return }
                    runReminderAction {
                        await appState.scheduleTaskReminder(
                            task.id,
                            on: customReminderDate,
                            context: "Reminder scheduled for custom date."
                        )
                    }
                    showCustomDatePicker = false
                }

                ODSecondaryButton(
                    title: "Cancel",
                    icon: "xmark",
                    isDisabled: isReminderActionInProgress
                ) {
                    showCustomDatePicker = false
                }
            }
            .padding(OneDoneStyle.screenPadding)
            .oneDoneScreen()
        }
    }

    private func scheduleReminder(_ task: MockTask, afterDays days: Int, context: String) {
        let reminderDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date().addingTimeInterval(86_400)
        runReminderAction {
            await appState.scheduleTaskReminder(task.id, on: reminderDate, context: context)
        }
    }

    private func runReminderAction(_ action: @escaping () async -> ReminderActionFeedback) {
        isReminderActionInProgress = true

        Task {
            let feedback = await action()
            await MainActor.run {
                reminderFeedback = feedback
                isReminderActionInProgress = false
            }
        }
    }

    private func reminderFeedbackTitle(_ feedback: ReminderActionFeedback) -> String {
        switch feedback.kind {
        case .success:
            return "Reminder updated"
        case .info:
            return "Reminder"
        case .warning:
            return "Notifications unavailable"
        }
    }

    private func reminderFeedbackTone(_ feedback: ReminderActionFeedback) -> ODStatusTone {
        switch feedback.kind {
        case .success:
            return .success
        case .info:
            return .neutral
        case .warning:
            return .warning
        }
    }

    private func reminderFeedbackIcon(_ feedback: ReminderActionFeedback) -> String {
        switch feedback.kind {
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "bell.slash"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func tone(for status: TaskStatus) -> ODStatusTone {
        switch status {
        case .followUpNeeded:
            return .warning
        case .dueSoon:
            return .warning
        case .needsClarification:
            return .warning
        case .waitingForReply:
            return .neutral
        case .inProgress:
            return .neutral
        case .new, .ready, .draft:
            return .highlight
        case .postponed:
            return .neutral
        case .done:
            return .success
        }
    }
}

#Preview {
    NavigationStack {
        let appState = AppState()
        TaskDetailView(appState: appState, taskID: appState.tasks[0].id)
    }
}
