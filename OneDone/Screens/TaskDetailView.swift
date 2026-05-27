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
    @State private var isLoadingRemoteTaskDetail: Bool = false
    @State private var remoteDetailErrorMessage: String?
    @State private var hasTriggeredInitialRemoteLoad: Bool = false

    private var task: MockTask? {
        appState.task(for: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                if let remoteDetailErrorMessage {
                    if appState.shouldUseRemoteTaskActions && task != nil {
                        ODInfoBanner(
                            title: "Showing last saved data",
                            message: "Showing last saved data. Pull to refresh.",
                            icon: "arrow.triangle.2.circlepath",
                            tone: .neutral
                        )
                    } else {
                        ODInfoBanner(
                            title: "Could not load task detail",
                            message: remoteDetailErrorMessage,
                            icon: "exclamationmark.triangle.fill",
                            tone: .warning
                        )
                    }

                    HStack {
                        Spacer(minLength: 0)
                        ODSecondaryButton(title: "Retry", icon: "arrow.clockwise", fullWidth: false) {
                            Task {
                                await refreshRemoteTaskDetail(showLoading: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }

                if shouldShowRemoteLoadingState {
                    ODCard(style: .muted) {
                        HStack(spacing: OneDoneStyle.tightSpacing) {
                            ProgressView()
                                .tint(ODColor.primary)
                            Text("Loading task details...")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

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
                    ODCard(style: .muted) {
                        Text(
                            appState.shouldUseRemoteTaskActions
                                ? "Task details are not available yet. Pull to refresh or return to My Tasks."
                                : "This task is no longer available."
                        )
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
        .refreshable {
            await refreshRemoteTaskDetail(showLoading: false)
        }
        .task {
            await loadRemoteTaskDetailIfNeeded()
        }
    }

    private func headerSection(_ task: MockTask) -> some View {
        ODCard(style: .default) {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                Text(task.title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(ODColor.textPrimary)
                    .lineLimit(3)

                HStack(alignment: .firstTextBaseline, spacing: OneDoneStyle.tightSpacing) {
                    Text(task.category)
                        .font(OneDoneStyle.captionFont.weight(.semibold))
                        .foregroundStyle(ODColor.textTertiary)
                        .lineLimit(1)

                    Spacer()

                    Text("Created \(dateTimeFormatter.string(from: task.createdAt))")
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func statusSection(_ task: MockTask) -> some View {
        ODCard(style: .default) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: OneDoneStyle.tightSpacing) {
                    ODStatusBadge(title: task.status.displayTitle, tone: tone(for: task.status))
                    ODStatusBadge(
                        title: appState.canCreateNewTasks ? "Access active" : "Access limited",
                        tone: appState.canCreateNewTasks ? .success : .locked
                    )

                    if let dateLabel = dueOrReminderText(task) {
                        ODStatusBadge(title: dateLabel, tone: .neutral)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func nextStepSection(_ task: MockTask) -> some View {
        ODCard(style: .strong) {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Current next step")
                Text(task.currentNextStep)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(ODColor.textPrimary)
                    .lineLimit(5)
            }
        }
    }

    private func checklistSection(_ task: MockTask) -> some View {
        ODCard(style: .muted) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                HStack {
                    cardTitle("Checklist")
                    Spacer()
                    if !task.actionPlan.isEmpty {
                        Text("\(task.actionPlan.count) items")
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                if task.actionPlan.isEmpty {
                    Text("No checklist items yet.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    VStack(spacing: OneDoneStyle.tightSpacing) {
                        ForEach(Array(task.actionPlan.enumerated()), id: \.offset) { _, step in
                            ChecklistRow(text: step, isChecked: false, isEnabled: true, onToggle: nil)
                        }
                    }
                }
            }
        }
    }

    private func latestOutputSection(_ task: MockTask) -> some View {
        ODCard(style: .muted) {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Latest AI output")
                Text(task.latestAIOutput)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
                    .lineLimit(6)
            }
        }
    }

    @ViewBuilder
    private func replyDraftSection(_ task: MockTask, replyDraft: String) -> some View {
        ODCard(style: .muted) {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Reply draft")
                Text(replyDraft)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
                    .lineLimit(5)

                NavigationLink {
                    DraftReplyView(appState: appState, taskID: task.id)
                } label: {
                    Text("Open Draft Reply")
                        .font(OneDoneStyle.captionFont.weight(.semibold))
                        .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(ODColor.glassFillSecondary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reminderSection(_ task: MockTask) -> some View {
        ODCard(style: .default) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Reminder")

                Text("Set a gentle follow-up. OneDone schedules locally first, then syncs.")
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)

                if let reminderDate = task.reminderDate {
                    reminderField(
                        label: "Date and time",
                        value: dateTimeFormatter.string(from: reminderDate),
                        icon: "bell"
                    )
                } else if let dueDate = task.dueDate {
                    reminderField(
                        label: "Due date",
                        value: dateTimeFormatter.string(from: dueDate),
                        icon: "calendar"
                    )
                } else {
                    reminderField(
                        label: "Date and time",
                        value: "Not set yet",
                        icon: "bell"
                    )
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
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity, alignment: .center)
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
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity, alignment: .center)
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
        ODCard(style: .muted) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Timeline")

                if compactTimeline(for: task).isEmpty {
                    Text("No timeline events yet.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    VStack(spacing: OneDoneStyle.tightSpacing) {
                        ForEach(compactTimeline(for: task)) { entry in
                            HStack(alignment: .top, spacing: OneDoneStyle.tightSpacing) {
                                Circle()
                                    .fill(ODColor.accentPrimaryDeepGreen)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(entry.title)
                                            .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                                            .foregroundStyle(ODColor.textPrimary)
                                            .lineLimit(1)

                                        Spacer()

                                        Text(dateFormatter.string(from: entry.date))
                                            .font(OneDoneStyle.captionFont)
                                            .foregroundStyle(ODColor.textMuted)
                                            .lineLimit(1)
                                    }

                                    Text(entry.detail)
                                        .font(OneDoneStyle.captionFont)
                                        .foregroundStyle(ODColor.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, OneDoneStyle.space4)
                            .overlay(alignment: .bottom) {
                                Divider()
                                    .overlay(ODColor.glassBorder.opacity(0.55))
                            }
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
            .foregroundStyle(ODColor.textSecondary)
            .textCase(.uppercase)
    }

    private func reminderField(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.space8) {
            Text(label)
                .font(OneDoneStyle.captionFont.weight(.semibold))
                .foregroundStyle(ODColor.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: OneDoneStyle.tightSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ODColor.accentPrimaryDeepGreen)

                Text(value)
                    .font(OneDoneStyle.subheadlineFont)
                    .foregroundStyle(ODColor.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
            .padding(.vertical, OneDoneStyle.controlVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                    .fill(ODColor.glassFillSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                    .stroke(ODColor.glassBorder, lineWidth: 0.9)
            )
        }
    }

    private var customDateSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODCard(style: .strong) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text("Choose reminder date")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(ODColor.textPrimary)

                        Text("Pick when OneDone should remind you.")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard(style: .default) {
                    DatePicker(
                        "Reminder date",
                        selection: $customReminderDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(ODColor.primary)
                }

                VStack(spacing: OneDoneStyle.contentSpacing) {
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
                .frame(maxWidth: 260)
                .frame(maxWidth: .infinity, alignment: .center)
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

    private var canLoadRemoteTaskDetail: Bool {
        appState.shouldUseRemoteTaskActions &&
            (task?.backendTaskID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
    }

    private var shouldShowRemoteLoadingState: Bool {
        canLoadRemoteTaskDetail && isLoadingRemoteTaskDetail
    }

    @MainActor
    private func loadRemoteTaskDetailIfNeeded() async {
        guard canLoadRemoteTaskDetail else {
            remoteDetailErrorMessage = nil
            return
        }

        guard !hasTriggeredInitialRemoteLoad else { return }
        hasTriggeredInitialRemoteLoad = true
        await refreshRemoteTaskDetail(showLoading: true)
    }

    @MainActor
    private func refreshRemoteTaskDetail(showLoading: Bool) async {
        guard canLoadRemoteTaskDetail else {
            remoteDetailErrorMessage = nil
            isLoadingRemoteTaskDetail = false
            return
        }

        if showLoading {
            isLoadingRemoteTaskDetail = true
        }

        let loadError = await appState.refreshTaskDetailFromRemote(taskID: taskID)
        remoteDetailErrorMessage = loadError
        if loadError == nil {
            reminderFeedback = nil
        }
        isLoadingRemoteTaskDetail = false
    }
}

#Preview {
    NavigationStack {
        let appState = AppState()
        TaskDetailView(appState: appState, taskID: appState.tasks[0].id)
    }
}
