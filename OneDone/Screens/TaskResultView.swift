import SwiftUI
import Observation

struct TaskResultView: View {
    @Bindable var appState: AppState
    let task: MockTask

    @State private var didSave = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(title: "Task Result", subtitle: "Ready to use")

                ODCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.headline)

                        Text(task.generatedReply)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suggested next steps")
                            .font(.headline)

                        ForEach(Array(task.actionPlan.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
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

                Button("Open My Tasks tab") {
                    appState.selectedTab = .tasks
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ODColor.primary)
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
