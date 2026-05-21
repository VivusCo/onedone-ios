import SwiftUI
import Observation

struct MyTasksView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(title: "My Tasks", subtitle: "Local mock history")

                if appState.tasks.isEmpty {
                    ODCard {
                        Text("No tasks yet. Create one from Home.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                } else {
                    ForEach(appState.tasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            ODCard {
                                VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                                    HStack(alignment: .center) {
                                        Text(task.title)
                                            .font(OneDoneStyle.cardTitleFont)
                                            .foregroundStyle(ODColor.textPrimary)

                                        Spacer()

                                        ODStatusBadge(
                                            title: task.status.rawValue,
                                            tone: tone(for: task.status)
                                        )
                                    }

                                    Text(task.generatedReply)
                                        .font(OneDoneStyle.subheadlineFont)
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

    private func tone(for status: TaskStatus) -> ODStatusTone {
        switch status {
        case .done:
            return .success
        case .ready:
            return .highlight
        case .inProgress:
            return .neutral
        case .draft:
            return .warning
        }
    }
}

#Preview {
    NavigationStack {
        MyTasksView(appState: AppState())
    }
}
