import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var appState: AppState

    @State private var taskInput: String = ""
    @State private var showNewTaskFromInput: Bool = false
    @State private var selectedQuickActionTemplate: TaskTemplate?
    @State private var showSubscriptionGate: Bool = false

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
                    title: accessIndicatorTitle,
                    tone: accessIndicatorTone
                )

                if let accessStatusNote = appState.accessStatusNote {
                    ODInfoBanner(
                        title: "Access update",
                        message: accessStatusNote,
                        icon: "info.circle.fill",
                        tone: accessStatusNoteTone
                    )
                }

                mainInputCard

                if appState.showsAccessGateForCreation {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ODInfoBanner(
                            title: "Creation is locked",
                            message: "You can still view existing tasks and details. New task creation is gated in this access state.",
                            icon: "lock.fill",
                            tone: .warning
                        )

                        ODSecondaryButton(title: "Open access options", icon: "lock.open") {
                            showSubscriptionGate = true
                        }
                    }
                }

                quickActionsSection
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("OneDone")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNewTaskFromInput) {
            NewTaskView(appState: appState, prefilledPrompt: taskInput.isBlank ? nil : taskInput)
        }
        .navigationDestination(item: $selectedQuickActionTemplate) { template in
            NewTaskView(
                appState: appState,
                prefilledPrompt: template.promptHint,
                selectedTemplate: template
            )
        }
        .sheet(isPresented: $showSubscriptionGate) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showSubscriptionGate = false
            }
        }
        .onAppear {
            if appState.consumePendingHomeGateState() != nil {
                showSubscriptionGate = true
            }
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
                        if appState.canCreateNewTasks {
                            showNewTaskFromInput = true
                        } else {
                            showSubscriptionGate = true
                        }
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
                    Button {
                        if appState.canCreateNewTasks {
                            selectedQuickActionTemplate = template
                        } else {
                            showSubscriptionGate = true
                        }
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
            generatedHint = "Paste the bill text and help me understand each charge in plain language."
        case "Write a complaint":
            generatedHint = "Draft a respectful complaint message with clear facts and a desired outcome."
        case "Reply to a message":
            generatedHint = "Paste the message text and draft a concise reply with one clear next step."
        default:
            generatedHint = "Help me with this task."
        }

        return TaskTemplate(
            title: label,
            promptHint: generatedHint,
            focus: "Clear and actionable"
        )
    }

    private var accessIndicatorTitle: String {
        switch appState.mockAccessState {
        case .unauthenticated:
            return "Sign in required"
        case .onboarding_required:
            return "Onboarding required"
        case .starter_active:
            return "Starter: \(appState.starterDaysRemaining) days left"
        case .trial_not_started:
            return "Trial not started"
        case .trial_active:
            return "Trial active"
        case .subscription_active:
            return "Subscription active"
        case .subscription_cancelled_active:
            return "Subscription active (canceled)"
        case .grace_period:
            return "Billing grace period"
        case .starter_expired:
            return "Starter expired"
        case .billing_issue:
            return "Billing issue"
        case .trial_expired:
            return "Trial expired"
        case .subscription_expired:
            return "Subscription expired"
        }
    }

    private var accessIndicatorTone: ODStatusTone {
        switch appState.mockAccessState {
        case .starter_active:
            return .highlight
        case .trial_active, .subscription_active, .subscription_cancelled_active:
            return .success
        case .grace_period, .starter_expired, .trial_not_started, .billing_issue, .trial_expired, .subscription_expired:
            return .warning
        case .unauthenticated, .onboarding_required:
            return .neutral
        }
    }

    private var accessStatusNoteTone: ODStatusTone {
        switch appState.mockAccessState {
        case .grace_period, .billing_issue:
            return .warning
        default:
            return .neutral
        }
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
