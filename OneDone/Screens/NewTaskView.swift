import SwiftUI
import Observation

struct NewTaskView: View {
    @Bindable var appState: AppState
    let prefilledPrompt: String?
    var selectedTemplate: TaskTemplate? = nil

    @State private var prompt: String = ""
    @State private var draft: TaskDraft?
    @State private var showClarification: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(
                    title: "New Task",
                    subtitle: "Describe one task in plain text"
                )

                if let selectedTemplate {
                    ODCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Template")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(ODColor.primary)
                            Text(selectedTemplate.title)
                                .font(.headline)
                            Text(selectedTemplate.focus)
                                .font(.subheadline)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Task prompt")
                            .font(.headline)
                            .foregroundStyle(ODColor.textPrimary)

                        TextEditor(text: $prompt)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(ODColor.cardBorder, lineWidth: 1)
                            )

                        Text("Attachments: Coming soon")
                            .font(.footnote)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODPrimaryButton(
                    title: "Continue to Clarification",
                    icon: "arrow.right",
                    isDisabled: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    draft = appState.makeDraft(prompt: prompt, template: selectedTemplate)
                    showClarification = true
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
    }
}

#Preview {
    NavigationStack {
        NewTaskView(appState: AppState(), prefilledPrompt: "Draft a follow-up for a product demo.")
    }
}
