import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Home",
                    subtitle: "Guided, text-first flow"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Welcome back")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text("Pick one task and move it forward with a calm, guided sequence.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        ODStatusBadge(
                            title: "Starter days remaining: \(appState.starterDaysRemaining)",
                            tone: .highlight
                        )
                    }
                }

                NavigationLink {
                    NewTaskView(appState: appState, prefilledPrompt: nil)
                } label: {
                    ODCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("New Task")
                                    .font(OneDoneStyle.cardTitleFont)
                                    .foregroundStyle(ODColor.textPrimary)
                                Text("Create a task with local mock guidance")
                                    .font(OneDoneStyle.subheadlineFont)
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
                        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                            Text("Latest task")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.primary)

                            Text(latest.title)
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)

                            Text(latest.generatedReply)
                                .font(OneDoneStyle.subheadlineFont)
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
