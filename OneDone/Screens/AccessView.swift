import SwiftUI
import Observation

struct AccessView: View {
    @Bindable var appState: AppState
    @State private var showGatePreview: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Access",
                    subtitle: "Mock starter, trial, and subscription states"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ODStatusBadge(
                            title: appState.mockAccessState.displayName,
                            tone: accessStatusTone
                        )

                        Text(appState.accessSummary)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        Text(appState.canCreateNewTasks ? "Creation is unlocked in this state." : "Creation is locked in this state. Existing tasks remain viewable.")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textPrimary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Mock access state")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        ForEach(MockAccessState.allCases) { state in
                            Button {
                                appState.setMockAccessState(state)
                            } label: {
                                HStack {
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

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gate preview")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text("Use this to test Starter and trial/subscription gate states without StoreKit.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        ODPrimaryButton(
                            title: "Open Subscription Gate",
                            icon: "lock.fill",
                            isDisabled: appState.canCreateNewTasks
                        ) {
                            showGatePreview = true
                        }
                    }
                }

                ODPrimaryButton(title: "Enter OneDone", icon: "arrow.right.circle") {
                    appState.enterMainApp()
                }
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

    private var accessStatusTone: ODStatusTone {
        switch appState.mockAccessState {
        case .starter_active, .trial_active, .subscription_active:
            return .success
        case .starter_expired, .trial_expired, .subscription_expired:
            return .warning
        case .billing_issue:
            return .warning
        }
    }
}

#Preview {
    AccessView(appState: AppState())
}
