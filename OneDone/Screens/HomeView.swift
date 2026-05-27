import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var appState: AppState

    @State private var selectedQuickActionTemplate: TaskTemplate?
    @State private var showSubscriptionGate: Bool = false

    private let shortcuts: [HomeShortcut] = [
        HomeShortcut(
            title: "Cancel subscription",
            subtitle: "Stop recurring charges.",
            icon: "xmark.circle",
            templateTitle: "Cancel a subscription",
            backendTemplateID: "cancel_subscription",
            fallbackPrompt: "Help me cancel a subscription and confirm I will not be billed again."
        ),
        HomeShortcut(
            title: "Request refund",
            subtitle: "Ask clearly and calmly.",
            icon: "creditcard.and.123",
            templateTitle: "Request a refund",
            backendTemplateID: "request_refund",
            fallbackPrompt: "Draft a refund request with clear facts and the refund amount."
        ),
        HomeShortcut(
            title: "Understand bill",
            subtitle: "Break down each charge.",
            icon: "doc.text.magnifyingglass",
            templateTitle: "Understand a bill",
            backendTemplateID: "understand_bill",
            fallbackPrompt: "Paste the bill text and explain each line item clearly."
        ),
        HomeShortcut(
            title: "Reply politely",
            subtitle: "Draft a respectful response.",
            icon: "bubble.left.and.text.bubble.right",
            templateTitle: "Reply to a message",
            backendTemplateID: "reply_to_message",
            fallbackPrompt: "Help me write a polite reply to this message with one clear next step."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                headerBar

                accessTopRow

                if let accessStatusNote = appState.accessStatusNote {
                    ODInfoBanner(
                        title: "Access update",
                        message: accessStatusNote,
                        icon: "info.circle.fill",
                        tone: accessStatusNoteTone
                    )
                }

                IllustrationCard(
                    title: "From messy to manageable",
                    subtitle: "OneDone turns vague admin stress into a clear next step.",
                    variant: .calm,
                    minHeight: 124
                )

                quickActionsSection

                nextUpSection

                if appState.showsAccessGateForCreation {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ODInfoBanner(
                            title: "Creation is locked",
                            message: "You can still view existing tasks and details. Start trial or restore access to create new tasks.",
                            icon: "lock.fill",
                            tone: .warning
                        )

                        ODSecondaryButton(title: "Open access options", icon: "lock.open") {
                            showSubscriptionGate = true
                        }
                    }
                }

                Color.clear
                    .frame(height: OneDoneStyle.tabRootContentBottomClearance)
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("OneDone")
        .navigationBarTitleDisplayMode(.inline)
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
        HStack(alignment: .top, spacing: OneDoneStyle.contentSpacing) {
            VStack(alignment: .leading, spacing: OneDoneStyle.space8) {
                Text("Good morning")
                    .font(OneDoneStyle.screenTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                Text("Pick one admin task and move it forward.")
                    .font(OneDoneStyle.helperFont)
                    .foregroundStyle(ODColor.textSecondary)
            }

            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ODColor.primary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                                .stroke(ODColor.glassBorder, lineWidth: 0.85)
                        )
                )
                .accessibilityLabel("Notifications")
        }
    }

    private var accessTopRow: some View {
        HStack(spacing: OneDoneStyle.tightSpacing) {
            ODStatusBadge(
                title: accessIndicatorTitle,
                tone: accessIndicatorTone
            )

            Spacer()

            Text("Tap + to add")
                .font(OneDoneStyle.captionFont.weight(.semibold))
                .foregroundStyle(ODColor.textSecondary)
        }
    }

    @ViewBuilder
    private var nextUpSection: some View {
        if let nextUpTask {
            ODCard(contentPadding: 14, style: .default) {
                VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next up")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.accentPrimaryDeepGreen)

                            Text(nextUpTask.title)
                                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                                .foregroundStyle(ODColor.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        ODStatusBadge(
                            title: nextUpTask.status.displayTitle,
                            tone: statusTone(for: nextUpTask.status)
                        )
                    }

                    Text(nextUpTask.currentNextStep)
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineLimit(1)

                    if let dateText = scheduleText(for: nextUpTask) {
                        Text(dateText)
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
        } else {
            ODCard(contentPadding: 14, style: .muted) {
                VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                    Text("Next up")
                        .font(OneDoneStyle.captionFont.weight(.semibold))
                        .foregroundStyle(ODColor.accentPrimaryDeepGreen)

                    Text("No active task yet")
                        .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                        .foregroundStyle(ODColor.textPrimary)

                    Text("Tap the Task button below to create your first task.")
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        ODCard(style: .default) {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What OneDone can help with")
                        .font(OneDoneStyle.cardHeadlineFont)
                        .foregroundStyle(ODColor.textPrimary)

                    Text("Choose a shortcut or tap + to start fresh.")
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: OneDoneStyle.contentSpacing) {
                    ForEach(shortcuts) { shortcut in
                        Button {
                            handleShortcutTap(shortcut)
                        } label: {
                            shortcutTile(shortcut)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(shortcut.title)
                    }
                }
            }
        }
    }

    private func shortcutTile(_ shortcut: HomeShortcut) -> some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
            Image(systemName: shortcut.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ODColor.accentPrimaryDeepGreen)

            Text(shortcut.title)
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(shortcut.subtitle)
                .font(OneDoneStyle.captionFont)
                .foregroundStyle(ODColor.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                        .fill(ODColor.glassFillSecondary)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: 0.85)
        )
    }

    private func handleShortcutTap(_ shortcut: HomeShortcut) {
        if appState.canCreateNewTasks {
            selectedQuickActionTemplate = template(for: shortcut)
            return
        }

        showSubscriptionGate = true
    }

    private func template(for shortcut: HomeShortcut) -> TaskTemplate {
        if let existing = appState.templates.first(where: { $0.title.lowercased() == shortcut.templateTitle.lowercased() }) {
            return TaskTemplate(
                title: shortcut.title,
                promptHint: existing.promptHint,
                focus: existing.focus,
                backendTemplateID: existing.resolvedBackendTemplateID
            )
        }

        return TaskTemplate(
            title: shortcut.title,
            promptHint: shortcut.fallbackPrompt,
            focus: "Clear and actionable",
            backendTemplateID: shortcut.backendTemplateID
        )
    }

    private var nextUpTask: MockTask? {
        appState.tasks
            .filter { $0.status != .done }
            .sorted { lhs, rhs in
                if lhs.status.sortPriority != rhs.status.sortPriority {
                    return lhs.status.sortPriority < rhs.status.sortPriority
                }

                let lhsDate = lhs.reminderDate ?? lhs.dueDate
                let rhsDate = rhs.reminderDate ?? rhs.dueDate

                switch (lhsDate, rhsDate) {
                case let (left?, right?):
                    if left != right {
                        return left < right
                    }
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    break
                }

                return lhs.createdAt > rhs.createdAt
            }
            .first
    }

    private func scheduleText(for task: MockTask) -> String? {
        if let reminderDate = task.reminderDate {
            return "Reminder \(dateFormatter.string(from: reminderDate))"
        }
        if let dueDate = task.dueDate {
            return "Due \(dateFormatter.string(from: dueDate))"
        }
        return nil
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func statusTone(for status: TaskStatus) -> ODStatusTone {
        switch status {
        case .followUpNeeded, .dueSoon, .needsClarification:
            return .warning
        case .waitingForReply, .inProgress, .postponed:
            return .neutral
        case .new, .ready, .draft:
            return .highlight
        case .done:
            return .success
        }
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

private struct HomeShortcut: Identifiable {
    let title: String
    let subtitle: String
    let icon: String
    let templateTitle: String
    let backendTemplateID: String
    let fallbackPrompt: String

    var id: String { title }
}

#Preview {
    NavigationStack {
        HomeView(appState: AppState())
    }
}
