import SwiftUI

struct TaskDetailView: View {
    let task: MockTask

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(title: task.title, subtitle: task.status.rawValue)

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Original prompt")
                            .font(.headline)
                        Text(task.prompt)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Clarification")
                            .font(.headline)
                        Text(task.clarification)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Generated reply")
                            .font(.headline)
                        Text(task.generatedReply)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Action plan")
                            .font(.headline)

                        ForEach(Array(task.actionPlan.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: MockRepository.seedTasks[0])
    }
}
