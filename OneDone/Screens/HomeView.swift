import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(
                    title: "Home",
                    subtitle: "Guided, text-first flow"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welcome back")
                            .font(.headline)
                            .foregroundStyle(ODColor.textPrimary)

                        Text("Pick one task and move it forward with a calm, guided sequence.")
                            .foregroundStyle(ODColor.textSecondary)

                        Text("Starter days remaining: \(appState.starterDaysRemaining)")
                            .font(.subheadline)
                            .foregroundStyle(ODColor.primary)
                    }
                }

                NavigationLink {
                    NewTaskView(appState: appState, prefilledPrompt: nil)
                } label: {
                    ODCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("New Task")
                                    .font(.headline)
                                    .foregroundStyle(ODColor.textPrimary)
                                Text("Create a task with local mock guidance")
                                    .font(.subheadline)
                                    .foregroundStyle(ODColor.textSecondary)
                            }

                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                                .foregroundStyle(ODColor.primary)
                        }
                    }
                }
                .buttonStyle(.plain)

                if let latest = appState.tasks.first {
                    ODCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latest task")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(ODColor.primary)

                            Text(latest.title)
                                .font(.headline)

                            Text(latest.generatedReply)
                                .font(.subheadline)
                                .foregroundStyle(ODColor.textSecondary)
                                .lineLimit(3)
                        }
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("OneDone")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }
}

#Preview {
    NavigationStack {
        HomeView(appState: AppState())
    }
}
