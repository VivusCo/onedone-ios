import SwiftUI
import Observation

struct AccessView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(
                    title: "Access",
                    subtitle: "Starter Access status and App Store trial gate (mock UI)"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        statusChip

                        Text(appState.accessSummary)
                            .foregroundStyle(ODColor.textSecondary)

                        Text("Starter Access: \(appState.starterAccessDaysUsed)/\(appState.starterAccessDaysTotal) day(s) used")
                            .font(.subheadline)
                            .foregroundStyle(ODColor.textPrimary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Starter Access")
                            .font(.headline)
                            .foregroundStyle(ODColor.textPrimary)

                        ODPrimaryButton(
                            title: appState.starterAccessStarted ? "Starter Access Started" : "Start Starter Access",
                            icon: "play.fill",
                            isDisabled: appState.starterAccessStarted
                        ) {
                            appState.startStarterAccess()
                        }

                        ODPrimaryButton(
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
                            .font(.headline)
                            .foregroundStyle(ODColor.textPrimary)

                        Text("14-day trial unlocks after Starter Access is completed.")
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

    private var statusChip: some View {
        Text(appState.appStoreTrialActivated ? "Trial active" : (appState.isTrialEligible ? "Trial available" : "Starter access"))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(ODColor.primarySoft)
            )
            .foregroundStyle(ODColor.primary)
    }
}

#Preview {
    AccessView(appState: AppState())
}
