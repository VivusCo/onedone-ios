import SwiftUI
import Observation

struct AccessView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Access",
                    subtitle: "Starter Access status and App Store trial gate (mock UI)"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ODStatusBadge(
                            title: accessStatusTitle,
                            tone: accessStatusTone
                        )

                        Text(appState.accessSummary)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        Text("Starter Access: \(appState.starterAccessDaysUsed)/\(appState.starterAccessDaysTotal) day(s) used")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textPrimary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Starter Access")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        ODPrimaryButton(
                            title: appState.starterAccessStarted ? "Starter Access Started" : "Start Starter Access",
                            icon: "play.fill",
                            isDisabled: appState.starterAccessStarted
                        ) {
                            appState.startStarterAccess()
                        }

                        ODSecondaryButton(
                            title: "Simulate Day Progress",
                            icon: "calendar.badge.plus",
                            isDisabled: !appState.starterAccessStarted || appState.starterDaysRemaining == 0
                        ) {
                            appState.simulateStarterDayProgress()
                        }
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Store Trial Gate")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text("14-day trial unlocks after Starter Access is completed.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        ODPrimaryButton(
                            title: appState.appStoreTrialActivated ? "Trial Activated (Mock)" : "Activate App Store Trial",
                            icon: "sparkles",
                            isDisabled: !appState.isTrialEligible || appState.appStoreTrialActivated
                        ) {
                            appState.activateAppStoreTrial()
                        }
                    }
                }

                ODPrimaryButton(title: "Enter OneDone", icon: "arrow.right.circle") {
                    appState.enterMainApp()
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .oneDoneScreen()
    }

    private var accessStatusTitle: String {
        if appState.appStoreTrialActivated {
            return "Trial active"
        }
        if appState.isTrialEligible {
            return "Trial available"
        }
        return "Starter access"
    }

    private var accessStatusTone: ODStatusTone {
        if appState.appStoreTrialActivated {
            return .success
        }
        return appState.isTrialEligible ? .highlight : .neutral
    }
}

#Preview {
    AccessView(appState: AppState())
}
