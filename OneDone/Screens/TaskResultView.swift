import SwiftUI
import Observation

struct TaskResultView: View {
    @Bindable var appState: AppState
    let task: MockTask

    @State private var didSave = false
    @State private var showTaskDetail = false
    @State private var showDraftReply = false
    // TODO(ui): Persist checklist completion when an official backend checklist update API is available.
    @State private var checkedChecklistIndexes: Set<Int> = []

    @Environment(\.dismiss) private var dismiss

    private var summaryText: String {
        task.generatedReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Review the suggested steps and continue with the next action."
            : task.generatedReply
    }

    private var nextStepText: String {
        if !task.currentNextStep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return task.currentNextStep
        }

        if let firstStep = checklistSteps.first {
            return firstStep
        }

        return "Open task details and continue with the first action."
    }

    private var checklistSteps: [String] {
        task.actionPlan
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var checklistProgressText: String {
        "\(checkedChecklistIndexes.count) of \(checklistSteps.count) checked"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                IllustrationCard(
                    title: "Useful path found",
                    subtitle: "Start with one clear action, then check items as you go.",
                    variant: .focused,
                    minHeight: 128
                )

                ODCard(style: .strong) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text("Next step")
                            .font(OneDoneStyle.captionFont.weight(.semibold))
                            .foregroundStyle(ODColor.accentPrimaryDeepGreen)

                        Text(nextStepText)
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(ODColor.textPrimary)
                            .lineLimit(4)
                    }
                }

                ODCard(style: .default) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text(task.title)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text(summaryText)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                            .lineLimit(5)
                    }
                }

                ODCard(style: .muted) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        HStack {
                            Text("Checklist")
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)

                            Spacer()

                            ODStatusBadge(
                                title: checklistSteps.isEmpty ? "No items yet" : "Tap to check",
                                tone: .success
                            )
                        }

                        if checklistSteps.isEmpty {
                            Text("No checklist items yet. Open task detail to continue.")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        } else {
                            VStack(spacing: OneDoneStyle.tightSpacing) {
                                ForEach(Array(checklistSteps.enumerated()), id: \.offset) { index, step in
                                    ChecklistRow(
                                        text: step,
                                        isChecked: checkedChecklistIndexes.contains(index),
                                        onToggle: {
                                            toggleChecklist(index)
                                        }
                                    )
                                    .accessibilityLabel("Checklist item \(index + 1): \(step)")
                                }
                            }

                            Text(checklistProgressText)
                                .font(OneDoneStyle.captionFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

                HStack(spacing: OneDoneStyle.contentSpacing) {
                    ODPrimaryButton(title: "Draft Reply", icon: "text.bubble", fullWidth: true) {
                        ensureTaskSaved()
                        showDraftReply = true
                    }

                    ODSecondaryButton(title: "Reminder", icon: "bell", fullWidth: true) {
                        ensureTaskSaved()
                        showTaskDetail = true
                    }
                }

                VStack(spacing: OneDoneStyle.tightSpacing) {
                    HStack {
                        Spacer(minLength: 0)
                        if didSave {
                            Text("Saved to My Tasks")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.textSecondary)
                        } else {
                            ODSecondaryButton(title: "Save to My Tasks", icon: "square.and.arrow.down", fullWidth: false) {
                                appState.saveTask(task)
                                didSave = true
                            }
                        }
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: OneDoneStyle.contentSpacing) {
                        ODSecondaryButton(title: "View Task Detail", icon: "doc.text", fullWidth: true) {
                            ensureTaskSaved()
                            showTaskDetail = true
                        }

                        ODSecondaryButton(title: "Open My Tasks", icon: "list.bullet", fullWidth: true) {
                            appState.selectedTab = .tasks
                            dismiss()
                        }
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showTaskDetail) {
            TaskDetailView(appState: appState, taskID: task.id)
        }
        .navigationDestination(isPresented: $showDraftReply) {
            DraftReplyView(appState: appState, taskID: task.id)
        }
        .oneDoneScreen()
    }

    private func ensureTaskSaved() {
        if !didSave {
            appState.saveTask(task)
            didSave = true
        }
    }

    private func toggleChecklist(_ index: Int) {
        if checkedChecklistIndexes.contains(index) {
            checkedChecklistIndexes.remove(index)
        } else {
            checkedChecklistIndexes.insert(index)
        }
    }
}

#Preview {
    NavigationStack {
        TaskResultView(appState: AppState(), task: MockRepository.seedTasks[0])
    }
}
