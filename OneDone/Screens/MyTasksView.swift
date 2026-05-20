import SwiftUI
import Observation

struct MyTasksView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(title: "My Tasks", subtitle: "Local mock history")

                if appState.tasks.isEmpty {
                    ODCard {
                        Text("No tasks yet. Create one from Home.")
                            .foregroundStyle(ODColor.textSecondary)
                    }
                } else {
                    ForEach(appState.tasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            ODCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(task.title)
                                            .font(.headline)
                                            .foregroundStyle(ODColor.textPrimary)

                                        Spacer()

                                        Text(task.status.rawValue)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(ODColor.primary)
                                    }

                                    Text(task.generatedReply)
                                        .font(.subheadline)
                                        .foregroundStyle(ODColor.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("My Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }
}

#Preview {
    NavigationStack {
        MyTasksView(appState: AppState())
    }
}
