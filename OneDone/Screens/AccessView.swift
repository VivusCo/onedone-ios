import SwiftUI
import Observation

struct AccessView: View {
    @Bindable var appState: AppState
    @State private var showGatePreview: Bool = false

    private let actionMaxWidth: CGFloat = 340

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Access",
                    subtitle: "Your current plan and available actions"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        ODStatusBadge(
                            title: appState.mockAccessState.displayName,
                            tone: accessStatusTone
                        )

                        Text(appState.accessSummary)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        Text(accessDescription)
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textPrimary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("What stays available")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        accessAvailabilityRow("View existing tasks and task details")
                        accessAvailabilityRow("Review previous outputs and reminders")

                        if appState.canCreateNewTasks {
                            accessAvailabilityRow("Create new tasks and generate new replies")
                        } else {
                            accessAvailabilityRow("New creation and generation actions are locked until access is active")
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

    private var accessDescription: String {
        appState.canCreateNewTasks
            ? "Creation is available in your current state."
            : "Creation is locked right now, but your existing tasks remain available."
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
