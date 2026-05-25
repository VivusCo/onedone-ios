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
                if let task {
                    replyComposerSection(task: task)
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

    private func replyComposerSection(task: MockTask) -> some View {
        ODCard(style: .strong) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                HStack(alignment: .center, spacing: OneDoneStyle.tightSpacing) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.space4) {
                        Text("Draft Reply")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(ODColor.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: OneDoneStyle.tightSpacing) {
                            ODStatusBadge(title: selectedTone.rawValue, tone: .highlight)
                            ODStatusBadge(title: selectedLanguage.rawValue, tone: .neutral)
                        }
                    }
                    Spacer()
                    compactCopyButton
                }

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

                TextEditor(text: $messageBody)
                    .font(OneDoneStyle.bodyFont)
                    .frame(minHeight: 210)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .fill(ODColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .stroke(ODColor.border, lineWidth: 1)
                    )

                HStack(spacing: OneDoneStyle.tightSpacing) {
                    ForEach(ReplyTone.allCases) { tone in
                        metadataToggle(
                            title: tone.rawValue,
                            isSelected: selectedTone == tone
                        ) {
                            selectedTone = tone
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ForEach(ReplyLanguage.allCases) { language in
                            metadataToggle(
                                title: language.rawValue,
                                isSelected: selectedLanguage == language
                            ) {
                                selectedLanguage = language
                            }
                        }
                    }
                }

                if didCopy {
                    Label("Copied", systemImage: "checkmark.circle.fill")
                        .font(OneDoneStyle.captionFont.weight(.semibold))
                        .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                        .accessibilityLabel("Copied to clipboard")
                }

                Text(task.title)
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
            Text("Need different wording?")
                .font(OneDoneStyle.captionFont)
                .foregroundStyle(ODColor.textSecondary)

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
            .frame(maxWidth: 240)
            .frame(maxWidth: .infinity, alignment: .leading)

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
        .padding(.horizontal, OneDoneStyle.space4)
    }

    private var postCopyPromptSection: some View {
        ODCard(style: .default) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                Text("Did you send it?")
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                Text("Mark it sent so OneDone can help you follow up.")
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)

                HStack(spacing: OneDoneStyle.contentSpacing) {
                    ODPrimaryButton(
                        title: "Yes, I sent it",
                        icon: "checkmark.circle.fill",
                        isDisabled: isSyncActionInProgress
                    ) {
                        Task {
                            await markAsSent()
                        }
                    }
                    .frame(maxWidth: .infinity)

                    ODSecondaryButton(title: "Not yet", icon: "clock", isDisabled: isSyncActionInProgress) {
                        showPostCopyPrompt = false
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack {
                    Spacer(minLength: 0)
                    ODSecondaryButton(title: "Remind me later", icon: "bell", isDisabled: isSyncActionInProgress) {
                        Task {
                            await remindMeLater()
                        }
                    }
                    .frame(maxWidth: 240)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var followUpReminderSection: some View {
        ODCard(style: .default) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                Text("Set follow-up reminder")
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                Text("Don’t hold it all in your head. Set a calm follow-up reminder now.")
                    .font(OneDoneStyle.subheadlineFont)
                    .foregroundStyle(ODColor.textSecondary)

                VStack(spacing: OneDoneStyle.contentSpacing) {
                    reminderButton(title: "Tomorrow", hours: 24)
                    reminderButton(title: "In 2 days", hours: 48)
                    reminderButton(title: "In 3 days", hours: 72)
                }
                .frame(maxWidth: 260)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var compactCopyButton: some View {
        Button {
            copyDraft()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                Text("Copy")
                    .font(OneDoneStyle.captionFont.weight(.semibold))
            }
            .foregroundStyle(
                messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSyncActionInProgress || isRegeneratingReply
                    ? ODColor.textTertiary
                    : ODColor.accentPrimaryDeepGreen
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(ODColor.glassFillSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ODColor.glassBorder, lineWidth: 0.9)
            )
        }
        .buttonStyle(.plain)
        .disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSyncActionInProgress || isRegeneratingReply)
        .accessibilityLabel("Copy")
        .accessibilityHint("Copies the draft to clipboard")
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
        .frame(maxWidth: .infinity)
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

    private func metadataToggle(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(OneDoneStyle.captionFont.weight(.semibold))
                .foregroundStyle(isSelected ? ODColor.primaryContrast : ODColor.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? ODColor.primary : ODColor.glassFillSecondary)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(ODColor.glassBorder, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
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
