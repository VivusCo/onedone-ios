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

    @Environment(\.dismiss) private var dismiss

    init(appState: AppState, initialDraft: TaskDraft) {
        self.appState = appState
        self.initialDraft = initialDraft
        _activeDraft = State(initialValue: initialDraft)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Clarification",
                    subtitle: "One quick detail before we continue"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text(activeDraft.clarificationQuestion)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        if hasOptions {
                            VStack(spacing: OneDoneStyle.tightSpacing) {
                                ForEach(activeDraft.clarificationOptions, id: \.self) { option in
                                    clarificationOptionRow(option)
                                }
                            }
                        } else {
                            ODTextField(
                                label: "Your answer",
                                placeholder: "Type your answer",
                                text: $manualAnswer
                            )
                        }
                    }
                }

                ODPrimaryButton(
                    title: "Continue",
                    icon: "arrow.right",
                    isDisabled: selectedClarificationAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
                ) {
                    Task {
                        await submitClarification()
                    }
                }

                ODSecondaryButton(title: "Skip for now", icon: "pause") {
                    let pendingTask = appState.makeNeedsClarificationTask(from: activeDraft)
                    appState.saveTask(pendingTask)
                    appState.selectedTab = .tasks
                    dismiss()
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
    }

    private var hasOptions: Bool {
        !activeDraft.clarificationOptions.isEmpty
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
        } catch {
            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                submitErrorMessage = description
            } else {
                submitErrorMessage = "Could not apply clarification right now. Please try again."
            }
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
                        .foregroundStyle(ODColor.primary)
                }
            }
            .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
            .padding(.vertical, OneDoneStyle.controlVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                    .fill(selectedOption == option ? ODColor.primarySoft : ODColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                    .stroke(ODColor.border, lineWidth: 1)
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
