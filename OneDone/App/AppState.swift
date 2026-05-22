import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case templates = "Templates"
    case tasks = "My Tasks"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .templates:
            return "square.grid.2x2.fill"
        case .tasks:
            return "checklist"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let body: String
}

extension APIAccessState: Identifiable {
    var id: String { rawValue }

    var creationAllowed: Bool {
        switch self {
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            return true
        case .unauthenticated, .onboarding_required, .starter_expired, .trial_not_started, .billing_issue, .trial_expired, .subscription_expired:
            return false
        }
    }

    var defaultStatusNote: String? {
        switch self {
        case .subscription_cancelled_active:
            return "Subscription is active until period end. Auto-renew is turned off."
        case .grace_period:
            return "Billing grace period is active. Please resolve billing to avoid interruptions."
        default:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .unauthenticated:
            return "Unauthenticated"
        case .onboarding_required:
            return "Onboarding Required"
        case .starter_active:
            return "Starter Active"
        case .starter_expired:
            return "Starter Expired"
        case .trial_not_started:
            return "Trial Not Started"
        case .trial_active:
            return "Trial Active"
        case .subscription_active:
            return "Subscription Active"
        case .subscription_cancelled_active:
            return "Subscription Cancelled (Active)"
        case .grace_period:
            return "Grace Period"
        case .billing_issue:
            return "Billing Issue"
        case .trial_expired:
            return "Trial Expired"
        case .subscription_expired:
            return "Subscription Expired"
        }
    }
}

enum ReminderActionKind {
    case success
    case info
    case warning
}

struct ReminderActionFeedback {
    let kind: ReminderActionKind
    let message: String
}

enum NewTaskAnalysisResult {
    case clarification(TaskDraft)
    case taskAnalysis(MockTask)
    case splitPreview(message: String)
}

@Observable
final class AppState {
    enum Phase {
        case welcome
        case onboarding
        case starterIntro
        case access
        case accessStateLoading
        case accessStateError
        case main
    }

    var phase: Phase
    var selectedTab: AppTab = .home

    var onboardingPageIndex: Int = 0
    var hasCompletedOnboarding: Bool = false
    var hasViewedStarterIntro: Bool = false
    let onboardingPages: [OnboardingPage] = [
        OnboardingPage(
            title: "OneDone keeps it simple",
            subtitle: "Guided self-service",
            body: "You bring a real task. OneDone helps you clarify it, draft a reply, and finish with calm momentum."
        ),
        OnboardingPage(
            title: "Text-first MVP",
            subtitle: "No noisy setup",
            body: "Start with plain text prompts and focused guidance. Attachments are intentionally disabled while we keep the core flow clean."
        ),
        OnboardingPage(
            title: "Progress in small steps",
            subtitle: "Starter Access first",
            body: "After onboarding, you get 3-day Starter Access. Then the App Store 14-day trial becomes available."
        )
    ]

    var starterAccessDaysTotal: Int = 3
    var starterAccessDaysUsed: Int = 0
    var starterAccessStarted: Bool = false
    var appStoreTrialActivated: Bool = false
    var mockAccessState: APIAccessState = .starter_active
    var accessStatusNote: String?
    var accessStateLoadErrorMessage: String?
    var pendingHomeGateState: APIAccessState?

    var remindersEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var calmModeEnabled: Bool = true
    let services: AppServiceContainer
    private var didAttemptRemoteAccessBootstrap: Bool = false
    private var isRefreshingRemoteAccessState: Bool = false
    private var forceMockTaskFlowInSession: Bool = false

    var templates: [TaskTemplate] = MockRepository.templates
    var tasks: [MockTask] = MockRepository.seedTasks

    init(services: AppServiceContainer = .mock) {
        self.services = services
        self.phase = services.runtimeMode == .remoteAccessState ? .accessStateLoading : .welcome
    }

    var currentOnboardingPage: OnboardingPage {
        onboardingPages[onboardingPageIndex]
    }

    var onboardingProgressText: String {
        "Step \(onboardingPageIndex + 1) of \(onboardingPages.count)"
    }

    var starterDaysRemaining: Int {
        max(0, starterAccessDaysTotal - starterAccessDaysUsed)
    }

    var isTrialEligible: Bool {
        starterAccessStarted && starterAccessDaysUsed >= starterAccessDaysTotal
    }

    var canCreateNewTasks: Bool {
        mockAccessState.creationAllowed
    }

    var showsAccessGateForCreation: Bool {
        !canCreateNewTasks
    }

    var accessSummary: String {
        switch mockAccessState {
        case .unauthenticated:
            return "Authentication is required to continue."
        case .onboarding_required:
            return "Onboarding is required before Starter Access begins."
        case .starter_active:
            return "\(starterDaysRemaining) day(s) of Starter Access remaining."
        case .starter_expired:
            return "Starter Access has ended. Trial is required to keep creating new tasks."
        case .trial_not_started:
            return "Starter Access ended. Start the App Store trial to keep creating new tasks."
        case .trial_active:
            return "App Store trial is active."
        case .subscription_active:
            return "Subscription is active."
        case .subscription_cancelled_active:
            return "Subscription remains active until period end."
        case .grace_period:
            return "Billing grace period is active. Resolve billing soon."
        case .billing_issue:
            return "There is a billing issue. Creation is temporarily locked."
        case .trial_expired:
            return "Trial has expired. Start a subscription to continue creating tasks."
        case .subscription_expired:
            return "Subscription has expired. Renew to continue creating tasks."
        }
    }

    func beginOnboarding() {
        phase = .onboarding
    }

    func nextOnboardingPage() {
        guard onboardingPageIndex < onboardingPages.count - 1 else {
            hasCompletedOnboarding = true
            phase = .starterIntro
            return
        }

        onboardingPageIndex += 1
    }

    func previousOnboardingPage() {
        guard onboardingPageIndex > 0 else { return }
        onboardingPageIndex -= 1
    }

    func completeStarterIntro() {
        hasViewedStarterIntro = true
    }

    func startStarterAccess() {
        starterAccessStarted = true
        if mockAccessState == .starter_expired || mockAccessState == .trial_not_started {
            setMockAccessState(.starter_active)
        }
    }

    func simulateStarterDayProgress() {
        guard starterAccessStarted else { return }
        starterAccessDaysUsed = min(starterAccessDaysUsed + 1, starterAccessDaysTotal)
        if starterDaysRemaining == 0 && mockAccessState == .starter_active {
            setMockAccessState(.starter_expired)
        }
    }

    func activateAppStoreTrial() {
        guard isTrialEligible else { return }
        appStoreTrialActivated = true
        setMockAccessState(.trial_active)
    }

    func activateMockSubscription() {
        setMockAccessState(.subscription_active)
    }

    func setMockAccessState(_ state: APIAccessState, statusNote: String? = nil) {
        mockAccessState = state
        accessStatusNote = statusNote ?? state.defaultStatusNote

        switch state {
        case .unauthenticated, .onboarding_required:
            starterAccessStarted = false
            appStoreTrialActivated = false
            starterAccessDaysUsed = 0
        case .starter_active:
            starterAccessStarted = true
            appStoreTrialActivated = false
            starterAccessDaysUsed = min(starterAccessDaysUsed, max(0, starterAccessDaysTotal - 1))
        case .starter_expired, .trial_not_started:
            starterAccessStarted = true
            appStoreTrialActivated = false
            starterAccessDaysUsed = starterAccessDaysTotal
        case .trial_active:
            starterAccessStarted = true
            appStoreTrialActivated = true
            starterAccessDaysUsed = starterAccessDaysTotal
        case .subscription_active, .subscription_cancelled_active, .grace_period:
            starterAccessStarted = true
            appStoreTrialActivated = false
            starterAccessDaysUsed = starterAccessDaysTotal
        case .billing_issue:
            starterAccessStarted = true
            appStoreTrialActivated = false
            starterAccessDaysUsed = starterAccessDaysTotal
        case .trial_expired:
            starterAccessStarted = true
            appStoreTrialActivated = false
            starterAccessDaysUsed = starterAccessDaysTotal
        case .subscription_expired:
            starterAccessStarted = true
            appStoreTrialActivated = false
            starterAccessDaysUsed = starterAccessDaysTotal
        }
    }

    func enterMainApp() {
        completeStarterIntro()
        startStarterAccess()
        phase = .main
    }

    @MainActor
    func bootstrapAccessStateIfNeeded() async {
        guard services.runtimeMode == .remoteAccessState else { return }
        guard !didAttemptRemoteAccessBootstrap else { return }

        didAttemptRemoteAccessBootstrap = true
        await refreshAccessStateFromRemote()
    }

    @MainActor
    func retryAccessStateLoad() async {
        guard services.runtimeMode == .remoteAccessState else { return }
        await refreshAccessStateFromRemote()
    }

    @MainActor
    func continueWithMockSafeModeForDevelopment() {
#if DEBUG
        guard services.runtimeMode == .remoteAccessState else { return }
        accessStateLoadErrorMessage = nil
        pendingHomeGateState = nil
        forceMockTaskFlowInSession = true
        setMockAccessState(.starter_active)
        phase = .welcome
#endif
    }

    var canUseMockSafeFallback: Bool {
#if DEBUG
        services.runtimeMode == .remoteAccessState
#else
        false
#endif
    }

    func consumePendingHomeGateState() -> APIAccessState? {
        let gateState = pendingHomeGateState
        pendingHomeGateState = nil
        return gateState
    }

    var shouldUseRemoteTaskAnalysis: Bool {
        services.runtimeMode == .remoteAccessState && !forceMockTaskFlowInSession
    }

    var shouldUseRemoteTaskActions: Bool {
        services.runtimeMode == .remoteAccessState && !forceMockTaskFlowInSession
    }

    func makeDraft(prompt: String, template: TaskTemplate?) -> TaskDraft {
        services.taskService.analyzeTask(prompt: prompt, template: template)
    }

    @MainActor
    func analyzeNewTask(
        prompt: String,
        selectedTemplate: TaskTemplate?,
        idempotencyKey: String
    ) async throws -> NewTaskAnalysisResult {
        if !shouldUseRemoteTaskAnalysis {
            let localDraft = makeDraft(prompt: prompt, template: selectedTemplate)

            if localDraft.requiresClarification {
                return .clarification(localDraft)
            }

            let localTask = finalizeTask(from: localDraft)
            return .taskAnalysis(localTask)
        }

        let request = AnalyzeTaskRequest(
            inputText: prompt,
            selectedTemplate: selectedTemplate?.resolvedBackendTemplateID,
            deadlineAtISO8601: nil,
            contextNotes: nil
        )

        let remoteResponse = try await services.taskService.submitAnalyzeTask(
            request,
            idempotencyKey: idempotencyKey
        )

        switch remoteResponse {
        case let .clarification(taskID, payload):
            let question = payload.question?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedQuestion = (question?.isEmpty == false) ? question! : "I need one quick detail before I continue."
            let options = payload.options
            let title = payload.title?.trimmingCharacters(in: .whitespacesAndNewlines)

            let draft = TaskDraft(
                backendTaskID: taskID,
                title: (title?.isEmpty == false) ? title! : inferredTaskTitle(from: prompt),
                prompt: prompt,
                intent: selectedTemplate?.resolvedBackendTemplateID == "cancel_subscription" ? .cancelSubscription : .generic,
                requiresClarification: true,
                clarificationQuestion: normalizedQuestion,
                clarificationOptions: options,
                generatedReply: "I need one quick detail before giving exact steps.",
                actionPlan: []
            )

            return .clarification(draft)
        case let .taskAnalysis(taskID, payload):
            let title = payload.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            let summary = payload.summary?.trimmingCharacters(in: .whitespacesAndNewlines)
            let latestOutput = payload.latestOutput?.trimmingCharacters(in: .whitespacesAndNewlines)
            let checklist = payload.checklist.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let nextSteps = payload.nextSteps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            let finalSummary = firstNonEmpty(
                summary,
                latestOutput,
                "Task analysis completed. Review the next step and continue."
            )
            let finalSteps = !nextSteps.isEmpty ? nextSteps : (!checklist.isEmpty ? checklist : ["Review the recommendation and take the first action."])

            let draft = TaskDraft(
                backendTaskID: taskID,
                title: firstNonEmpty(title, inferredTaskTitle(from: prompt)),
                prompt: prompt,
                intent: selectedTemplate?.resolvedBackendTemplateID == "cancel_subscription" ? .cancelSubscription : .generic,
                requiresClarification: false,
                clarificationQuestion: "",
                clarificationOptions: [],
                generatedReply: finalSummary,
                actionPlan: finalSteps
            )

            var task = finalizeTask(from: draft)
            task.backendTaskID = taskID

            if let category = payload.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
                task.category = category
            }

            task.latestAIOutput = finalSummary
            task.currentNextStep = finalSteps.first ?? task.currentNextStep
            task.lastEventPreview = "Analysis complete."

            return .taskAnalysis(task)
        case let .multiTaskSplitPreview(_, payload):
            let itemTitles = payload.items.map(\.title).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let fallbackMessage = "Multiple tasks were detected. Split-task confirmation is not connected yet in this build."
            let message = firstNonEmpty(payload.message, payload.title, fallbackMessage)
            let details = itemTitles.isEmpty ? message : "\(message)\n\nSuggested tasks:\n- \(itemTitles.joined(separator: "\n- "))"
            return .splitPreview(message: details)
        }
    }

    func applyClarification(answer: String, to draft: TaskDraft) -> TaskDraft {
        services.taskService.answerClarification(answer: answer, draft: draft)
    }

    @MainActor
    func resolveClarification(
        answer: String,
        for draft: TaskDraft,
        idempotencyKey: String
    ) async throws -> NewTaskAnalysisResult {
        if !shouldUseRemoteTaskActions || draft.backendTaskID == nil {
            let clarifiedDraft = applyClarification(answer: answer, to: draft)
            let task = finalizeTask(from: clarifiedDraft)
            return .taskAnalysis(task)
        }

        guard let backendTaskID = draft.backendTaskID else {
            throw TaskActionServiceError.missingBackendTaskID
        }

        let request = AnswerClarificationRequest(taskID: backendTaskID, answer: answer)
        let remoteResponse = try await services.taskService.submitAnswerClarification(
            request,
            idempotencyKey: idempotencyKey
        )

        switch remoteResponse {
        case let .clarification(taskID, payload):
            var updatedDraft = draft
            updatedDraft.backendTaskID = taskID
            updatedDraft.requiresClarification = true
            updatedDraft.clarificationQuestion = firstNonEmpty(payload.question, "I need one more detail before I continue.")
            updatedDraft.clarificationOptions = payload.options
            updatedDraft.generatedReply = "I need one quick detail before giving exact steps."
            updatedDraft.actionPlan = []
            return .clarification(updatedDraft)
        case let .taskAnalysis(taskID, payload):
            let summary = firstNonEmpty(
                payload.summary,
                payload.latestOutput,
                "Task analysis completed. Review the next step and continue."
            )
            let checklist = payload.checklist.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let nextSteps = payload.nextSteps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let finalSteps = !nextSteps.isEmpty ? nextSteps : (!checklist.isEmpty ? checklist : ["Review the recommendation and take the first action."])

            let resultDraft = TaskDraft(
                backendTaskID: taskID,
                title: firstNonEmpty(payload.title, draft.title, inferredTaskTitle(from: draft.prompt)),
                prompt: draft.prompt,
                intent: draft.intent,
                requiresClarification: false,
                clarificationQuestion: "",
                clarificationOptions: [],
                clarificationAnswer: answer,
                generatedReply: summary,
                actionPlan: finalSteps
            )

            var task = finalizeTask(from: resultDraft)
            task.backendTaskID = taskID
            if let category = payload.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
                task.category = category
            }
            task.latestAIOutput = summary
            task.currentNextStep = finalSteps.first ?? task.currentNextStep
            task.lastEventPreview = "Analysis complete."
            return .taskAnalysis(task)
        case let .multiTaskSplitPreview(_, payload):
            let itemTitles = payload.items.map(\.title).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let fallbackMessage = "Multiple tasks were detected. Split-task confirmation is not connected yet in this build."
            let message = firstNonEmpty(payload.message, payload.title, fallbackMessage)
            let details = itemTitles.isEmpty ? message : "\(message)\n\nSuggested tasks:\n- \(itemTitles.joined(separator: "\n- "))"
            return .splitPreview(message: details)
        }
    }

    @MainActor
    func requestReplyRegeneration(
        taskID: UUID,
        tone: String,
        language: String
    ) async throws -> GenerateReplyResponse {
        guard shouldUseRemoteTaskActions else {
            throw TaskActionServiceError.remoteActionsDisabled
        }

        guard let task = task(for: taskID) else {
            throw TaskActionServiceError.invalidResponse
        }

        guard let backendTaskID = task.backendTaskID, !backendTaskID.isEmpty else {
            throw TaskActionServiceError.missingBackendTaskID
        }

        let request = GenerateReplyRequest(
            taskID: backendTaskID,
            tone: tone,
            language: language
        )

        let response = try await services.taskService.submitGenerateReply(
            request,
            idempotencyKey: UUID().uuidString.lowercased()
        )

        updateTask(taskID) { task in
            task.replyDraft = response.message
            task.generatedReply = response.message
            task.latestAIOutput = response.message
            task.lastEventPreview = "Reply regenerated."
            task.timeline.append(
                TaskTimelineEntry(
                    title: "Reply regenerated",
                    detail: "Tone: \(tone), Language: \(language).",
                    date: Date()
                )
            )
        }

        return response
    }

    @MainActor
    func markTaskSentAndSync(_ taskID: UUID, sentMessage: String) async -> String? {
        markTaskWaitingForReply(taskID, sentMessage: sentMessage)

        guard shouldUseRemoteTaskActions else {
            return nil
        }

        guard let task = task(for: taskID), let backendTaskID = task.backendTaskID, !backendTaskID.isEmpty else {
            return "Marked as sent locally. This task is not linked to backend yet."
        }

        let request = MessageMarkedSentRequest(
            taskID: backendTaskID,
            sentAtISO8601: ISO8601DateFormatter().string(from: Date())
        )

        do {
            let response = try await services.taskService.submitMessageMarkedSent(
                request,
                idempotencyKey: UUID().uuidString.lowercased()
            )

            let normalizedStatus = TaskStatus.fromBackend(response.status)
            if normalizedStatus != .new {
                updateTask(taskID) { task in
                    task.status = normalizedStatus
                }
            }
            return nil
        } catch {
            return "Marked as sent locally, but backend sync failed. \(friendlyRemoteErrorMessage(error))"
        }
    }

    @MainActor
    func updateTaskStatusAndSync(
        _ taskID: UUID,
        to status: TaskStatus,
        reason: String? = nil
    ) async -> String? {
        updateTask(taskID) { task in
            task.status = status
            task.lastEventPreview = "Status updated to \(status.displayTitle)."
            task.timeline.append(
                TaskTimelineEntry(
                    title: "Status updated",
                    detail: "Status changed to \(status.displayTitle).",
                    date: Date()
                )
            )
        }

        guard shouldUseRemoteTaskActions else {
            return nil
        }

        guard let task = task(for: taskID), let backendTaskID = task.backendTaskID, !backendTaskID.isEmpty else {
            return "Status updated locally. This task is not linked to backend yet."
        }

        do {
            _ = try await services.taskService.submitUpdateTaskStatus(
                UpdateTaskStatusRequest(
                    taskID: backendTaskID,
                    status: status.backendValue,
                    reason: reason
                ),
                idempotencyKey: UUID().uuidString.lowercased()
            )
            return nil
        } catch {
            return "Status updated locally, but backend sync failed. \(friendlyRemoteErrorMessage(error))"
        }
    }

    func finalizeTask(from draft: TaskDraft, status: TaskStatus = .ready) -> MockTask {
        services.taskService.createTask(from: draft, status: status)
    }

    func makeNeedsClarificationTask(from draft: TaskDraft) -> MockTask {
        services.taskService.createTask(from: draft, status: .needsClarification)
    }

    func saveTask(_ task: MockTask) {
        if tasks.contains(where: { $0.id == task.id }) {
            return
        }

        if let backendTaskID = task.backendTaskID,
           tasks.contains(where: { $0.backendTaskID == backendTaskID }) {
            return
        }

        tasks.insert(task, at: 0)
    }

    func task(for id: UUID) -> MockTask? {
        tasks.first(where: { $0.id == id })
    }

    func markTaskWaitingForReply(_ taskID: UUID, sentMessage: String) {
        updateTask(taskID) { task in
            task.status = .waitingForReply
            task.replyDraft = sentMessage
            task.latestAIOutput = "Message sent. Wait for a response before the follow-up reminder."
            task.currentNextStep = "Wait for reply, then follow up if needed."
            task.lastEventPreview = "Reply sent. Waiting for response."
            task.timeline.append(
                TaskTimelineEntry(
                    title: "Reply sent",
                    detail: "Status moved to Waiting for Reply.",
                    date: Date()
                )
            )
        }
    }

    func setTaskReminder(_ taskID: UUID, afterHours hours: Int, context: String) {
        let reminderDate = Calendar.current.date(byAdding: .hour, value: max(1, hours), to: Date())

        updateTask(taskID) { task in
            task.reminderDate = reminderDate
            task.reminderNotificationID = nil
            task.lastEventPreview = "Reminder set."
            task.timeline.append(
                TaskTimelineEntry(
                    title: "Reminder set",
                    detail: context,
                    date: Date()
                )
            )
        }
    }

    @MainActor
    func scheduleTaskReminder(_ taskID: UUID, on date: Date, context: String) async -> ReminderActionFeedback {
        guard let existingTask = task(for: taskID) else {
            return ReminderActionFeedback(kind: .warning, message: "Task not found.")
        }

        let safeDate = max(date, Date().addingTimeInterval(60))
        let scheduleResult = await services.reminderService.scheduleReminder(
            taskTitle: existingTask.title,
            date: safeDate
        )

        switch scheduleResult {
        case let .scheduled(identifier):
            if let previousID = existingTask.reminderNotificationID {
                services.reminderService.cancelReminder(identifier: previousID)
            }

            var backendSyncWarning: String?

            if shouldUseRemoteTaskActions,
               let backendTaskID = existingTask.backendTaskID,
               !backendTaskID.isEmpty {
                do {
                    let syncResponse: ReminderSyncResponse
                    if let existingReminderID = existingTask.backendReminderID {
                        syncResponse = try await services.reminderService.syncReminderUpdate(
                            ReminderUpdateRequest(
                                taskID: backendTaskID,
                                reminderID: existingReminderID,
                                remindAtISO8601: ISO8601DateFormatter().string(from: safeDate),
                                iosNotificationID: identifier
                            )
                        )
                    } else {
                        syncResponse = try await services.reminderService.syncReminderCreate(
                            ReminderCreateRequest(
                                taskID: backendTaskID,
                                remindAtISO8601: ISO8601DateFormatter().string(from: safeDate),
                                iosNotificationID: identifier
                            )
                        )
                    }

                    updateTask(taskID) { task in
                        if let reminderID = syncResponse.reminderID, !reminderID.isEmpty {
                            task.backendReminderID = reminderID
                        }
                    }
                } catch {
                    backendSyncWarning = friendlyRemoteErrorMessage(error)
                }
            }

            updateTask(taskID) { task in
                task.reminderDate = safeDate
                task.reminderNotificationID = identifier
                task.lastEventPreview = "Reminder scheduled."
                task.timeline.append(
                    TaskTimelineEntry(
                        title: "Reminder scheduled",
                        detail: context,
                        date: Date()
                    )
                )
            }

            if let backendSyncWarning {
                return ReminderActionFeedback(
                    kind: .warning,
                    message: "Reminder set for \(friendlyDateTime(safeDate)) on this device, but backend sync failed. \(backendSyncWarning)"
                )
            }

            return ReminderActionFeedback(kind: .success, message: "Reminder set for \(friendlyDateTime(safeDate)).")
        case .permissionDenied:
            return ReminderActionFeedback(
                kind: .warning,
                message: "Notifications are off for OneDone. Enable them in Settings to get reminders."
            )
        case .failed:
            return ReminderActionFeedback(
                kind: .warning,
                message: "Could not schedule reminder right now. Please try again."
            )
        }
    }

    @MainActor
    func cancelTaskReminder(_ taskID: UUID) async -> ReminderActionFeedback {
        guard let existingTask = task(for: taskID) else {
            return ReminderActionFeedback(kind: .warning, message: "Task not found.")
        }

        guard existingTask.reminderDate != nil || existingTask.reminderNotificationID != nil else {
            return ReminderActionFeedback(kind: .info, message: "No active reminder to cancel.")
        }

        if let reminderID = existingTask.reminderNotificationID {
            services.reminderService.cancelReminder(identifier: reminderID)
        }

        var backendSyncWarning: String?
        if shouldUseRemoteTaskActions,
           let backendTaskID = existingTask.backendTaskID,
           !backendTaskID.isEmpty {
            do {
                _ = try await services.reminderService.syncReminderCancel(
                    ReminderCancelRequest(
                        taskID: backendTaskID,
                        reminderID: existingTask.backendReminderID,
                        iosNotificationID: existingTask.reminderNotificationID
                    )
                )
            } catch {
                backendSyncWarning = friendlyRemoteErrorMessage(error)
            }
        }

        updateTask(taskID) { task in
            task.reminderDate = nil
            task.reminderNotificationID = nil
            task.backendReminderID = nil
            task.lastEventPreview = "Reminder canceled."
            task.timeline.append(
                TaskTimelineEntry(
                    title: "Reminder canceled",
                    detail: "Local reminder removed.",
                    date: Date()
                )
            )
        }

        if let backendSyncWarning {
            return ReminderActionFeedback(
                kind: .warning,
                message: "Reminder canceled on this device, but backend sync failed. \(backendSyncWarning)"
            )
        }

        return ReminderActionFeedback(kind: .success, message: "Reminder canceled.")
    }

    @MainActor
    func snoozeTaskReminder(_ taskID: UUID, byHours hours: Int = 1) async -> ReminderActionFeedback {
        guard let existingTask = task(for: taskID) else {
            return ReminderActionFeedback(kind: .warning, message: "Task not found.")
        }

        let baseDate = max(existingTask.reminderDate ?? Date(), Date())
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: max(1, hours), to: baseDate) ??
            Date().addingTimeInterval(3600)

        let scheduleResult = await services.reminderService.scheduleReminder(
            taskTitle: existingTask.title,
            date: snoozeDate
        )

        switch scheduleResult {
        case let .scheduled(identifier):
            if let previousID = existingTask.reminderNotificationID {
                services.reminderService.cancelReminder(identifier: previousID)
            }

            var backendSyncWarning: String?
            if shouldUseRemoteTaskActions,
               let backendTaskID = existingTask.backendTaskID,
               !backendTaskID.isEmpty {
                do {
                    let syncResponse = try await services.reminderService.syncReminderSnooze(
                        ReminderSnoozeRequest(
                            taskID: backendTaskID,
                            reminderID: existingTask.backendReminderID,
                            iosNotificationID: identifier,
                            remindAtISO8601: ISO8601DateFormatter().string(from: snoozeDate),
                            snoozeMinutes: max(1, hours) * 60
                        )
                    )

                    updateTask(taskID) { task in
                        if let reminderID = syncResponse.reminderID, !reminderID.isEmpty {
                            task.backendReminderID = reminderID
                        }
                    }
                } catch {
                    backendSyncWarning = friendlyRemoteErrorMessage(error)
                }
            }

            updateTask(taskID) { task in
                task.reminderDate = snoozeDate
                task.reminderNotificationID = identifier
                task.lastEventPreview = "Reminder snoozed."
                task.timeline.append(
                    TaskTimelineEntry(
                        title: "Reminder snoozed",
                        detail: "Reminder snoozed by \(max(1, hours)) hour.",
                        date: Date()
                    )
                )
            }

            if let backendSyncWarning {
                return ReminderActionFeedback(
                    kind: .warning,
                    message: "Reminder snoozed on this device, but backend sync failed. \(backendSyncWarning)"
                )
            }

            return ReminderActionFeedback(
                kind: .success,
                message: "Reminder snoozed until \(friendlyDateTime(snoozeDate))."
            )
        case .permissionDenied:
            return ReminderActionFeedback(
                kind: .warning,
                message: "Notifications are off for OneDone. Enable them in Settings to snooze reminders."
            )
        case .failed:
            return ReminderActionFeedback(
                kind: .warning,
                message: "Could not snooze reminder right now. Please try again."
            )
        }
    }

    @MainActor
    private func refreshAccessStateFromRemote() async {
        guard services.runtimeMode == .remoteAccessState else { return }
        guard !isRefreshingRemoteAccessState else { return }

        isRefreshingRemoteAccessState = true
        phase = .accessStateLoading
        accessStateLoadErrorMessage = nil
        defer { isRefreshingRemoteAccessState = false }

        do {
            let snapshot = try await services.accessStateService.getAccessState()
            applyAccessSnapshot(snapshot)
        } catch {
            accessStateLoadErrorMessage = friendlyAccessStateError(for: error)
            phase = .accessStateError
        }
    }

    @MainActor
    private func applyAccessSnapshot(_ snapshot: AccessStateSnapshot) {
        setMockAccessState(snapshot.state, statusNote: snapshot.statusNote)

        if let starterDaysRemaining = snapshot.starterDaysRemaining {
            let clampedRemaining = min(max(starterDaysRemaining, 0), starterAccessDaysTotal)
            starterAccessDaysUsed = starterAccessDaysTotal - clampedRemaining
        }

        selectedTab = .home
        pendingHomeGateState = nil

        switch snapshot.state {
        case .onboarding_required:
            hasCompletedOnboarding = false
            onboardingPageIndex = 0
            phase = .onboarding
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            phase = .main
        case .starter_expired, .trial_not_started, .billing_issue, .trial_expired, .subscription_expired:
            pendingHomeGateState = snapshot.state
            phase = .main
        case .unauthenticated:
            phase = .welcome
            accessStatusNote = "Authentication flow is not connected in this mock build."
        }
    }

    private func friendlyAccessStateError(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return "We could not load your access state right now. Please check your connection and try again."
    }

    private func inferredTaskTitle(from prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "New task" }
        return String(trimmed.prefix(36))
    }

    private func firstNonEmpty(_ values: String?...) -> String {
        for value in values {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return ""
    }

    private func friendlyRemoteErrorMessage(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let message = localizedError.errorDescription {
            return message
        }

        return "Please try again."
    }

    private func updateTask(_ taskID: UUID, update: (inout MockTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        update(&tasks[index])
    }

    private func friendlyDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
