import SwiftUI
import Observation

struct NewTaskView: View {
    @Bindable var appState: AppState
    let prefilledPrompt: String?
    var selectedTemplate: TaskTemplate? = nil

    @State private var prompt: String = ""
    @State private var draft: TaskDraft?
    @State private var showClarification: Bool = false
    @State private var taskResult: MockTask?
    @State private var showTaskResult: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "New Task",
                    subtitle: "Describe one task in plain text"
                )

                if let selectedTemplate {
                    ODCard {
                        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                            Text("Template")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.primary)
                            Text(selectedTemplate.title)
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)
                            Text(selectedTemplate.focus)
                                .font(OneDoneStyle.subheadlineFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Task prompt")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        TextEditor(text: $prompt)
                            .font(OneDoneStyle.bodyFont)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                    .fill(ODColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                    .stroke(ODColor.border, lineWidth: 1)
                            )

                        ODComingSoonBadge(text: "Attachments coming soon")
                    }
                }

                ODPrimaryButton(
                    title: "Analyze Task",
                    icon: "arrow.right",
                    isDisabled: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    let createdDraft = appState.makeDraft(prompt: prompt, template: selectedTemplate)

                    if createdDraft.requiresClarification {
                        draft = createdDraft
                        showClarification = true
                    } else {
                        taskResult = appState.finalizeTask(from: createdDraft)
                        showTaskResult = true
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .onAppear {
            if prompt.isEmpty {
                prompt = prefilledPrompt ?? ""
            }
        }
        .navigationDestination(isPresented: $showClarification) {
            if let draft {
                ClarificationView(appState: appState, initialDraft: draft)
            }
        }
        .navigationDestination(isPresented: $showTaskResult) {
            if let taskResult {
                TaskResultView(appState: appState, task: taskResult)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewTaskView(appState: AppState(), prefilledPrompt: "Draft a follow-up for a product demo.")
    }
}
