import SwiftUI
import Observation

struct ClarificationView: View {
    @Bindable var appState: AppState
    let initialDraft: TaskDraft

    @State private var activeDraft: TaskDraft
    @State private var selectedOption: String?
    @State private var manualAnswer: String = ""
    @State private var taskResult: MockTask?
    @State private var showTaskResult: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var submitErrorMessage: String?
    @State private var splitPreviewMessage: String?
    @State private var showSubscriptionGate: Bool = false

    @Environment(\.dismiss) private var dismiss

    init(appState: AppState, initialDraft: TaskDraft) {
        self.appState = appState
        self.initialDraft = initialDraft
        _activeDraft = State(initialValue: initialDraft)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODCard(style: .strong) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        ODStatusBadge(title: "Needs clarification", tone: .warning)

                        Text("One detail to continue")
                            .font(OneDoneStyle.sectionLabelFont)
                            .foregroundStyle(ODColor.accentPrimaryDeepGreen)

                        Text(activeDraft.clarificationQuestion)
                            .font(OneDoneStyle.sectionTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text(clarificationContextText)
                            .font(OneDoneStyle.helperFont)
                            .foregroundStyle(ODColor.textSecondary)
                            .lineLimit(3)
                    }
                }

                if hasOptions {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ForEach(activeDraft.clarificationOptions, id: \.self) { option in
                            clarificationOptionRow(option)
                        }
                    }
                } else {
                    ODCard {
                        ODTextField(
                            label: "Your answer",
                            placeholder: "Type your answer",
                            text: $manualAnswer
                        )
                    }
                }

                VStack(spacing: OneDoneStyle.contentSpacing) {
                    HStack {
                        Spacer(minLength: 0)
                        ODPrimaryButton(
                            title: "Continue",
                            icon: "arrow.right",
                            isDisabled: selectedClarificationAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
                        ) {
                            Task {
                                await submitClarification()
                            }
                        }
                        .frame(maxWidth: 280)
                        Spacer(minLength: 0)
                    }

                    HStack {
                        Spacer(minLength: 0)
                        ODSecondaryButton(title: "Skip for now", icon: "pause") {
                            let pendingTask = appState.makeNeedsClarificationTask(from: activeDraft)
                            appState.saveTask(pendingTask)
                            appState.selectedTab = .tasks
                            if appState.shouldUseRemoteTaskActions {
                                Task {
                                    _ = await appState.refreshTasksFromRemote()
                                }
                            }
                            dismiss()
                        }
                        .frame(maxWidth: 280)
                        Spacer(minLength: 0)
                    }
                }

                if isSubmitting {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ProgressView()
                            .tint(ODColor.primary)
                        Text("Applying clarification...")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                if let submitErrorMessage {
                    ODInfoBanner(
                        title: "Could not continue",
                        message: submitErrorMessage,
                        icon: "exclamationmark.triangle.fill",
                        tone: .warning
                    )
                }

                if let splitPreviewMessage {
                    ODInfoBanner(
                        title: "Multiple tasks detected",
                        message: splitPreviewMessage,
                        icon: "list.bullet.rectangle",
                        tone: .neutral
                    )
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Clarification")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .navigationDestination(isPresented: $showTaskResult) {
            if let taskResult {
                TaskResultView(appState: appState, task: taskResult)
            }
        }
        .sheet(isPresented: $showSubscriptionGate) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showSubscriptionGate = false
            }
        }
    }

    private var hasOptions: Bool {
        !activeDraft.clarificationOptions.isEmpty
    }

    private var clarificationContextText: String {
        hasOptions
            ? "This missing detail changes the next steps."
            : "Share one short detail so we can continue with the right path."
    }

    private var selectedClarificationAnswer: String {
        if hasOptions {
            return selectedOption ?? ""
        }

        return manualAnswer
    }

    @MainActor
    private func submitClarification() async {
        guard !isSubmitting else { return }
        let answer = selectedClarificationAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }

        isSubmitting = true
        submitErrorMessage = nil
        splitPreviewMessage = nil
        defer { isSubmitting = false }

        do {
            let result = try await appState.resolveClarification(
                answer: answer,
                for: activeDraft,
                idempotencyKey: UUID().uuidString.lowercased()
            )

            switch result {
            case let .taskAnalysis(task):
                taskResult = task
                showTaskResult = true
            case let .clarification(nextDraft):
                activeDraft = nextDraft
                selectedOption = nil
                manualAnswer = ""
            case let .splitPreview(message):
                splitPreviewMessage = message
            }
        } catch let actionError as TaskActionServiceError {
            handleClarificationActionError(actionError)
        } catch is SupabaseAuthServiceError {
            appState.authErrorMessage = "Your session expired. Please log in again."
            appState.phase = .auth
        } catch {
            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                submitErrorMessage = description
            } else {
                submitErrorMessage = "Could not apply clarification right now. Please try again."
            }
        }
    }

    @MainActor
    private func handleClarificationActionError(_ error: TaskActionServiceError) {
        switch error {
        case let .accessDenied(message):
            let normalized = message.lowercased()
            if normalized.contains("session") ||
                normalized.contains("log in") ||
                normalized.contains("unauthorized") {
                appState.authErrorMessage = "Your session expired. Please log in again."
                appState.phase = .auth
                return
            }

            submitErrorMessage = message
            showSubscriptionGate = true
        default:
            submitErrorMessage = error.errorDescription ?? "Could not apply clarification right now. Please try again."
        }
    }

    @ViewBuilder
    private func clarificationOptionRow(_ option: String) -> some View {
        Button {
            selectedOption = option
        } label: {
            HStack {
                Text(option)
                    .font(OneDoneStyle.subheadlineFont.weight(.medium))
                    .foregroundStyle(ODColor.textPrimary)

                Spacer()

                if selectedOption == option {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ODColor.textTertiary)
                }
            }
            .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                            .fill(selectedOption == option ? ODColor.primarySoft.opacity(0.9) : ODColor.glassFillSecondary)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                    .stroke(ODColor.glassBorder, lineWidth: 0.9)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ClarificationView(
            appState: AppState(),
            initialDraft: TaskDraft(
                title: "Cancel subscription",
                prompt: "cancel_subscription",
                intent: .cancelSubscription,
                requiresClarification: true,
                clarificationQuestion: "Where is this subscription billed?",
                clarificationOptions: MockRepository.cancelSubscriptionClarificationOptions,
                generatedReply: "",
                actionPlan: []
            )
        )
    }
}
