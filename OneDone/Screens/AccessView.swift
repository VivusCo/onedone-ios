import SwiftUI
import Observation

struct AccessView: View {
    @Bindable var appState: AppState
    @State private var showGatePreview: Bool = false

    private let actionMaxWidth: CGFloat = 340

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODCard(style: .strong) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        ODStatusBadge(
                            title: friendlyAccessLabel,
                            tone: accessStatusTone
                        )

                        Text(accessHeadline)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(ODColor.textPrimary)
                            .lineLimit(3)

                        Text(appState.accessSummary)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard(style: .default) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Current availability")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        capabilityRow(
                            title: "Saved tasks",
                            value: "Available"
                        )
                        capabilityRow(
                            title: "Saved outputs",
                            value: "Available"
                        )
                        capabilityRow(
                            title: "New task creation",
                            value: appState.canCreateNewTasks ? "Available" : "Locked"
                        )
                        capabilityRow(
                            title: "Draft replies",
                            value: appState.canCreateNewTasks ? "Available" : "Locked"
                        )
                        capabilityRow(
                            title: "Reminders",
                            value: appState.canCreateNewTasks ? "Available" : "View only"
                        )
                    }
                }

                if !appState.canCreateNewTasks {
                    ODCard(style: .muted) {
                        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                            Text("Still available")
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)

                            accessAvailabilityRow("View existing tasks and task details")
                            accessAvailabilityRow("Review previous outputs and reminders")
                            accessAvailabilityRow("Restore purchases")
                        }
                    }
                }

                if !appState.canCreateNewTasks {
                    centeredAction {
                        ODPrimaryButton(title: "Start 14-day trial", icon: "sparkles") {
                            showGatePreview = true
                        }
                    }

                    centeredAction {
                        ODSecondaryButton(title: "Restore Purchases", icon: "arrow.clockwise") {
                            showGatePreview = true
                        }
                    }
                }

                centeredAction {
                    ODSecondaryButton(title: appState.canCreateNewTasks ? "Continue" : "Continue in limited mode", icon: "arrow.right") {
                        appState.enterMainApp()
                    }
                }

#if DEBUG
                if appState.services.runtimeMode == .mock {
                    ODCard(style: .muted) {
                        VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                            Text("Developer preview controls")
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)

                            Text("Use local mock states for development and previews.")
                                .font(OneDoneStyle.subheadlineFont)
                                .foregroundStyle(ODColor.textSecondary)

                            ForEach(APIAccessState.allCases) { state in
                                Button {
                                    appState.setMockAccessState(state)
                                } label: {
                                    HStack(spacing: OneDoneStyle.tightSpacing) {
                                        Text(state.displayName)
                                            .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                                            .foregroundStyle(ODColor.textPrimary)
                                        Spacer()
                                        if appState.mockAccessState == state {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(ODColor.primary)
                                        }
                                    }
                                    .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
                                    .padding(.vertical, OneDoneStyle.controlVerticalPadding)
                                    .background(
                                        RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                            .fill(appState.mockAccessState == state ? ODColor.primarySoft : ODColor.surfaceStrong)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
#endif
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .sheet(isPresented: $showGatePreview) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showGatePreview = false
            }
        }
        .oneDoneScreen()
    }

    private var friendlyAccessLabel: String {
        switch appState.mockAccessState {
        case .starter_active:
            return "Starter active"
        case .starter_expired:
            return "Starter ended"
        case .trial_not_started:
            return "Trial required"
        case .trial_active:
            return "Trial active"
        case .trial_expired:
            return "Trial ended"
        case .subscription_active:
            return "Subscription active"
        case .subscription_cancelled_active:
            return "Subscription active"
        case .subscription_expired:
            return "Subscription ended"
        case .grace_period:
            return "Billing grace period"
        case .billing_issue:
            return "Billing issue"
        case .onboarding_required:
            return "Onboarding required"
        case .unauthenticated:
            return "Login required"
        }
    }

    private var accessHeadline: String {
        switch appState.mockAccessState {
        case .starter_active:
            return "3 days to try the full loop."
        case .starter_expired, .trial_not_started:
            return "Keep using OneDone."
        case .trial_active, .subscription_active, .subscription_cancelled_active:
            return "Access is active."
        case .grace_period:
            return "Access is active while billing is resolved."
        case .billing_issue:
            return "Creation is locked until billing is resolved."
        case .trial_expired, .subscription_expired:
            return "Creation is locked until access is renewed."
        case .onboarding_required:
            return "Finish onboarding to unlock Starter Access."
        case .unauthenticated:
            return "Sign in to continue."
        }
    }

    private func accessAvailabilityRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: OneDoneStyle.tightSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ODColor.primary)
                .padding(.top, 1)
            Text(text)
                .font(OneDoneStyle.subheadlineFont)
                .foregroundStyle(ODColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func capabilityRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: OneDoneStyle.tightSpacing) {
            Text(title)
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.textPrimary)

            Spacer(minLength: OneDoneStyle.tightSpacing)

            Text(value)
                .font(OneDoneStyle.subheadlineFont)
                .foregroundStyle(ODColor.textSecondary)
                .lineLimit(1)
        }
        .padding(.vertical, OneDoneStyle.space4)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(ODColor.glassBorder.opacity(0.65))
        }
    }

    private func centeredAction<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            Spacer(minLength: 0)
            content()
                .frame(maxWidth: actionMaxWidth)
            Spacer(minLength: 0)
        }
    }

    private var accessStatusTone: ODStatusTone {
        switch appState.mockAccessState {
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active:
            return .success
        case .grace_period, .starter_expired, .trial_not_started, .trial_expired, .subscription_expired:
            return .warning
        case .billing_issue:
            return .warning
        case .unauthenticated, .onboarding_required:
            return .neutral
        }
    }
}

#Preview {
    AccessView(appState: AppState())
}
