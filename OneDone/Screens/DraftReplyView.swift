import SwiftUI
import Observation

struct DraftReplyView: View {
    @Bindable var appState: AppState
    let draft: TaskDraft

    @State private var finalizedTask: MockTask?
    @State private var showResult: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Draft Reply",
                    subtitle: "Mock generated text"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Reply Draft")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text(draft.generatedReply)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Action Plan")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        ForEach(Array(draft.actionPlan.enumerated()), id: \.offset) { index, item in
                            Text("\(index + 1). \(item)")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

                ODPrimaryButton(title: "Finalize Task Result", icon: "checkmark.circle.fill") {
                    finalizedTask = appState.finalizeTask(from: draft)
                    showResult = true
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Draft Reply")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .navigationDestination(isPresented: $showResult) {
            if let finalizedTask {
                TaskResultView(appState: appState, task: finalizedTask)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DraftReplyView(
            appState: AppState(),
            draft: MockRepository.makeDraft(prompt: "Write a calm weekly update", template: nil)
        )
    }
}
