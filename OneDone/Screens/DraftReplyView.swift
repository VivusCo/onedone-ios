import SwiftUI
import Observation
import UIKit

struct DraftReplyView: View {
    @Bindable var appState: AppState
    let taskID: UUID

    @State private var subject: String = ""
    @State private var messageBody: String = ""
    @State private var selectedTone: ReplyTone = .polite
    @State private var selectedLanguage: ReplyLanguage = .auto
    @State private var didCopy: Bool = false
    @State private var showPostCopyPrompt: Bool = false
    @State private var showFollowUpReminderFlow: Bool = false
    @State private var reminderFeedback: ReminderActionFeedback?
    @State private var actionFeedback: String?
    @State private var isSyncActionInProgress: Bool = false
    @State private var isRegeneratingReply: Bool = false
    @State private var showSubscriptionGate: Bool = false

    private var task: MockTask? {
        appState.task(for: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Draft Reply",
                    subtitle: "Review, copy, and track follow-up"
                )

                if let task {
                    subjectSection(task: task)
                    messageBodySection
                    toneSection
                    languageSection
                    actionsSection

                    if showPostCopyPrompt {
                        postCopyPromptSection
                    }

                    if showFollowUpReminderFlow {
                        followUpReminderSection
                    }

                    if let reminderFeedback {
                        ODInfoBanner(
                            title: reminderFeedbackTitle(reminderFeedback),
                            message: reminderFeedback.message,
                            icon: reminderFeedbackIcon(reminderFeedback),
                            tone: reminderFeedbackTone(reminderFeedback)
                        )
                    }

                    if let actionFeedback {
                        ODInfoBanner(
                            title: "Sync update",
                            message: actionFeedback,
                            icon: "info.circle.fill",
                            tone: .warning
                        )
                    }
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
        .navigationTitle("Draft Reply")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .sheet(isPresented: $showSubscriptionGate) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showSubscriptionGate = false
            }
        }
        .onAppear {
            guard let task else { return }
            if subject.isEmpty {
                subject = makeDefaultSubject(for: task)
            }
            if messageBody.isEmpty {
                messageBody = task.replyDraft ?? task.generatedReply
            }
        }
    }

    private func subjectSection(task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Subject")
                TextField("Subject", text: $subject)
                    .font(OneDoneStyle.bodyFont)
                    .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
                    .padding(.vertical, OneDoneStyle.controlVerticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .fill(ODColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .stroke(ODColor.border, lineWidth: 1)
                    )

                Text(task.title)
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textMuted)
            }
        }
    }

    private var messageBodySection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Message body")
                TextEditor(text: $messageBody)
                    .font(OneDoneStyle.bodyFont)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .fill(ODColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .stroke(ODColor.border, lineWidth: 1)
                    )
            }
        }
    }

    private var toneSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Tone")
                Picker("Tone", selection: $selectedTone) {
                    ForEach(ReplyTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var languageSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Language")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ForEach(ReplyLanguage.allCases) { language in
                            Button {
                                selectedLanguage = language
                            } label: {
                                Text(language.rawValue)
                                    .font(OneDoneStyle.captionFont.weight(.semibold))
                                    .foregroundStyle(
                                        selectedLanguage == language ? ODColor.primaryContrast : ODColor.textPrimary
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(selectedLanguage == language ? ODColor.primary : ODColor.surfaceStrong)
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(ODColor.border, lineWidth: selectedLanguage == language ? 0 : 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: OneDoneStyle.contentSpacing) {
            ODPrimaryButton(
                title: didCopy ? "Copied" : "Copy",
                icon: didCopy ? "checkmark" : "doc.on.doc",
                isDisabled: messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSyncActionInProgress || isRegeneratingReply
            ) {
                copyDraft()
            }

            ODSecondaryButton(
                title: isRegeneratingReply ? "Regenerating..." : "Regenerate",
                icon: "arrow.clockwise",
                isDisabled: isRegeneratingReply || isSyncActionInProgress
            ) {
                guard appState.canCreateNewTasks else {
                    showSubscriptionGate = true
                    return
                }

                Task {
                    await regenerateDraft()
                }
            }

            if isRegeneratingReply {
                HStack(spacing: OneDoneStyle.tightSpacing) {
                    ProgressView()
                        .tint(ODColor.primary)
                    Text("Generating reply...")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                }
            }
        }
    }

    private var postCopyPromptSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                Text("Did you send it?")
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                ODPrimaryButton(
                    title: "Yes, I sent it",
                    icon: "checkmark.circle.fill",
                    isDisabled: isSyncActionInProgress
                ) {
                    Task {
                        await markAsSent()
                    }
                }

                ODSecondaryButton(title: "Not yet", icon: "clock", isDisabled: isSyncActionInProgress) {
                    showPostCopyPrompt = false
                }

                ODSecondaryButton(title: "Remind me later", icon: "bell", isDisabled: isSyncActionInProgress) {
                    Task {
                        await remindMeLater()
                    }
                }
            }
        }
    }

    private var followUpReminderSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                Text("Set follow-up reminder")
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                Text("Choose when OneDone should remind you to check for a reply.")
                    .font(OneDoneStyle.subheadlineFont)
                    .foregroundStyle(ODColor.textSecondary)

                HStack(spacing: OneDoneStyle.tightSpacing) {
                    reminderButton(title: "Tomorrow", hours: 24)
                    reminderButton(title: "In 2 days", hours: 48)
                    reminderButton(title: "In 3 days", hours: 72)
                }
            }
        }
    }

    private func reminderButton(title: String, hours: Int) -> some View {
        Button {
            Task {
                await setFollowUpReminder(hours: hours)
            }
        } label: {
            Text(title)
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

    private func copyDraft() {
        let composed = "Subject: \(subject)\n\n\(messageBody)"
        UIPasteboard.general.string = composed
        didCopy = true
        showPostCopyPrompt = true
        showFollowUpReminderFlow = false
        reminderFeedback = nil
        actionFeedback = nil
    }

    private func regenerateMockDraft() {
        messageBody = regenerateMessage(
            base: messageBody,
            tone: selectedTone,
            language: selectedLanguage
        )
        didCopy = false
    }

    @MainActor
    private func regenerateDraft() async {
        guard !isRegeneratingReply else { return }
        guard appState.canCreateNewTasks else {
            showSubscriptionGate = true
            return
        }

        isRegeneratingReply = true
        actionFeedback = nil
        defer { isRegeneratingReply = false }

        if appState.services.runtimeMode == .remoteAccessState {
            guard appState.shouldUseRemoteTaskActions else {
                actionFeedback = "Please log in again to regenerate this reply."
                return
            }

            guard let task else {
                actionFeedback = "Task is unavailable right now."
                return
            }

            guard task.backendTaskID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                actionFeedback = "This task is missing a backend identifier, so reply regeneration is unavailable."
                return
            }

            do {
                let response = try await appState.requestReplyRegeneration(
                    taskID: taskID,
                    tone: selectedTone.rawValue.lowercased(),
                    language: selectedLanguage.rawValue.lowercased()
                )
                if let subjectResponse = response.subject, !subjectResponse.isEmpty {
                    subject = subjectResponse
                }
                messageBody = response.message
                didCopy = false
            } catch {
                actionFeedback = (error as? LocalizedError)?.errorDescription ?? "Could not regenerate reply right now."
            }
            return
        }

        regenerateMockDraft()
    }

    @MainActor
    private func markAsSent() async {
        guard !isSyncActionInProgress else { return }
        isSyncActionInProgress = true
        defer { isSyncActionInProgress = false }

        let syncWarning = await appState.markTaskSentAndSync(taskID, sentMessage: messageBody)
        actionFeedback = syncWarning
        if let syncWarning {
            let normalized = syncWarning.lowercased()
            if normalized.contains("session") ||
                normalized.contains("log in") ||
                normalized.contains("unauthorized") {
                appState.authErrorMessage = "Your session expired. Please log in again."
                appState.phase = .auth
                return
            }
        }
        showPostCopyPrompt = false
        showFollowUpReminderFlow = true
        reminderFeedback = nil
    }

    @MainActor
    private func remindMeLater() async {
        let reminderDate = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date().addingTimeInterval(3 * 3600)
        let feedback = await appState.scheduleTaskReminder(
            taskID,
            on: reminderDate,
            context: "Reminder from Draft Reply: send this message."
        )
        reminderFeedback = feedback
        showPostCopyPrompt = false
    }

    @MainActor
    private func setFollowUpReminder(hours: Int) async {
        let reminderDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date()) ?? Date().addingTimeInterval(Double(hours) * 3600)
        let feedback = await appState.scheduleTaskReminder(
            taskID,
            on: reminderDate,
            context: "Follow-up reminder after sent reply."
        )
        reminderFeedback = feedback
    }

    private func reminderFeedbackTitle(_ feedback: ReminderActionFeedback) -> String {
        switch feedback.kind {
        case .success:
            return "Reminder saved"
        case .info:
            return "Reminder"
        case .warning:
            return "Reminder issue"
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

    private func regenerateMessage(base: String, tone: ReplyTone, language: ReplyLanguage) -> String {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty ? "Could you help with this request?" : trimmed
        let tonePrefix = "[\(tone.rawValue)]"
        let languageSuffix = language == .auto ? "" : " (\(language.rawValue))"
        return "\(tonePrefix)\(languageSuffix) \(source)"
    }

    private func makeDefaultSubject(for task: MockTask) -> String {
        "Regarding: \(task.title)"
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(OneDoneStyle.captionFont.weight(.semibold))
            .foregroundStyle(ODColor.primary)
    }
}

private enum ReplyTone: String, CaseIterable, Identifiable {
    case polite = "Polite"
    case firmer = "Firmer"
    case shorter = "Shorter"

    var id: String { rawValue }
}

private enum ReplyLanguage: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case english = "English"
    case russian = "Russian"
    case ukrainian = "Ukrainian"
    case romanian = "Romanian"

    var id: String { rawValue }
}

#Preview {
    NavigationStack {
        let appState = AppState()
        DraftReplyView(appState: appState, taskID: appState.tasks[0].id)
    }
}
