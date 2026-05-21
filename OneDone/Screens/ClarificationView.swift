import SwiftUI
import Observation

struct ClarificationView: View {
    @Bindable var appState: AppState
    let initialDraft: TaskDraft

    @State private var selectedOption: String?
    @State private var manualAnswer: String = ""
    @State private var taskResult: MockTask?
    @State private var showTaskResult: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Clarification",
                    subtitle: "One quick detail before we continue"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text(initialDraft.clarificationQuestion)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        if hasOptions {
                            VStack(spacing: OneDoneStyle.tightSpacing) {
                                ForEach(initialDraft.clarificationOptions, id: \.self) { option in
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
                    isDisabled: selectedClarificationAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    let clarifiedDraft = appState.applyClarification(answer: selectedClarificationAnswer, to: initialDraft)
                    taskResult = appState.finalizeTask(from: clarifiedDraft)
                    showTaskResult = true
                }

                ODSecondaryButton(title: "Skip for now", icon: "pause") {
                    let pendingTask = appState.makeNeedsClarificationTask(from: initialDraft)
                    appState.saveTask(pendingTask)
                    appState.selectedTab = .tasks
                    dismiss()
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
        !initialDraft.clarificationOptions.isEmpty
    }

    private var selectedClarificationAnswer: String {
        if hasOptions {
            return selectedOption ?? ""
        }

        return manualAnswer
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
