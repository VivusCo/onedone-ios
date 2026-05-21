import SwiftUI
import Observation

struct TaskResultView: View {
    @Bindable var appState: AppState
    let task: MockTask

    @State private var didSave = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(title: "Task Result", subtitle: "Ready to use")

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text(task.title)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text(task.generatedReply)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Suggested next steps")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        ForEach(Array(task.actionPlan.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

                ODPrimaryButton(
                    title: didSave ? "Saved to My Tasks" : "Save to My Tasks",
                    icon: didSave ? "checkmark" : "square.and.arrow.down",
                    isDisabled: didSave
                ) {
                    appState.saveTask(task)
                    didSave = true
                }

                ODSecondaryButton(title: "Open My Tasks tab", icon: "list.bullet") {
                    appState.selectedTab = .tasks
                    dismiss()
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }
}

#Preview {
    NavigationStack {
        TaskResultView(appState: AppState(), task: MockRepository.seedTasks[0])
    }
}
