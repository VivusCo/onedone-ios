import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var appState: AppState

    @State private var taskInput: String = ""
    @State private var showNewTaskFromInput: Bool = false

    private let quickActionLabels: [String] = [
        "Cancel a subscription",
        "Return an item",
        "Request a refund",
        "Understand a bill",
        "Write a complaint",
        "Reply to a message"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                headerBar

                ODStatusBadge(
                    title: "Starter: \(appState.starterDaysRemaining) days left",
                    tone: .highlight
                )

                mainInputCard

                quickActionsSection
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("OneDone")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNewTaskFromInput) {
            NewTaskView(appState: appState, prefilledPrompt: taskInput.isBlank ? nil : taskInput)
        }
        .oneDoneScreen()
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            ODSectionHeader(
                title: "Home",
                subtitle: "Start with one task"
            )

            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ODColor.primary)
                .padding(10)
                .background(
                    Circle()
                        .fill(ODColor.surfaceStrong)
                )
                .accessibilityLabel("Notifications")
        }
    }

    private var mainInputCard: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                Text("What do you need to deal with?")
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                TextEditor(text: $taskInput)
                    .font(OneDoneStyle.bodyFont)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .fill(ODColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                            .stroke(ODColor.border, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if taskInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("What do you need to deal with?")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textMuted)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 16)
                        }
                    }

                Text("Paste a message, bill, document text, or describe the task.")
                    .font(OneDoneStyle.subheadlineFont)
                    .foregroundStyle(ODColor.textSecondary)

                HStack(alignment: .center) {
                    ODComingSoonBadge(text: "Attachments coming soon")

                    Spacer()

                    ODPrimaryButton(
                        title: "Send task",
                        icon: "arrow.right",
                        fullWidth: false
                    ) {
                        showNewTaskFromInput = true
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
            Text("Quick actions")
                .font(OneDoneStyle.cardTitleFont)
                .foregroundStyle(ODColor.textPrimary)

            ForEach(quickActionLabels, id: \.self) { label in
                if let template = template(for: label) {
                    NavigationLink {
                        NewTaskView(appState: appState, prefilledPrompt: template.promptHint, selectedTemplate: template)
                    } label: {
                        ODCard(contentPadding: 14) {
                            HStack {
                                Text(label)
                                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                                    .foregroundStyle(ODColor.textPrimary)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(ODColor.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func template(for label: String) -> TaskTemplate? {
        let desiredTitle = label.lowercased()

        if let exact = appState.templates.first(where: { $0.title.lowercased() == desiredTitle }) {
            return exact
        }

        let generatedHint: String
        switch label {
        case "Cancel a subscription":
            generatedHint = "Help me write a clear cancellation request for a subscription and ask for confirmation."
        case "Return an item":
            generatedHint = "Draft a return request message for an item I purchased, including order details and preferred resolution."
        case "Request a refund":
            generatedHint = "Write a calm refund request that explains the issue and asks for a timeline."
        case "Understand a bill":
            generatedHint = "Help me understand this bill line-by-line and identify anything unusual."
        case "Write a complaint":
            generatedHint = "Draft a respectful complaint message with clear facts and a desired outcome."
        case "Reply to a message":
            generatedHint = "Draft a concise reply to this message with a clear next step."
        default:
            generatedHint = "Help me with this task."
        }

        return TaskTemplate(
            title: label,
            promptHint: generatedHint,
            focus: "Clear and actionable"
        )
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    NavigationStack {
        HomeView(appState: AppState())
    }
}
