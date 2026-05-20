import SwiftUI
import Observation

struct DraftReplyView: View {
    @Bindable var appState: AppState
    let draft: TaskDraft

    @State private var finalizedTask: MockTask?
    @State private var showResult: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(
                    title: "Draft Reply",
                    subtitle: "Mock generated text"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reply Draft")
                            .font(.headline)
                            .foregroundStyle(ODColor.textPrimary)

                        Text(draft.generatedReply)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Action Plan")
                            .font(.headline)

                        ForEach(Array(draft.actionPlan.enumerated()), id: \.offset) { index, item in
                            Text("\(index + 1). \(item)")
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
