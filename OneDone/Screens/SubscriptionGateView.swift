import SwiftUI
import Observation

struct SubscriptionGateView: View {
    @Bindable var appState: AppState
    let accessState: APIAccessState
    var onActivated: (() -> Void)? = nil

    @State private var linkFeedback: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: headline,
                    subtitle: "Access required"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text(subtext)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODPrimaryButton(
                    title: ctaTitle,
                    icon: "sparkles",
                    isDisabled: isCTAButtonDisabled
                ) {
                    handleCTAAction()
                }

                secondaryLinks

                if let linkFeedback {
                    ODInfoBanner(
                        title: "Mock action",
                        message: linkFeedback,
                        icon: "info.circle.fill",
                        tone: .neutral
                    )
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Access Gate")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }

    private var headline: String {
        switch accessState {
        case .starter_expired, .trial_not_started:
            return "Keep using OneDone."
        case .billing_issue:
            return "We couldn't verify billing."
        case .trial_expired:
            return "Your trial has ended."
        case .subscription_expired:
            return "Your subscription has ended."
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            return "Access active"
        case .onboarding_required:
            return "Finish onboarding"
        case .unauthenticated:
            return "Sign in required"
        }
    }

    private var subtext: String {
        switch accessState {
        case .starter_expired, .trial_not_started:
            return "Your Starter Access has ended. Start your 14-day App Store trial to keep using task breakdowns, replies, reminders, and follow-ups."
        case .billing_issue:
            return "Creation is temporarily locked in this mock billing issue state. Resolve billing to continue creating new tasks."
        case .trial_expired:
            return "Your mock trial has ended. Start a subscription to continue creating new tasks."
        case .subscription_expired:
            return "Your mock subscription has ended. Renew to continue creating new tasks."
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            return appState.accessStatusNote ?? "Your access is active."
        case .onboarding_required:
            return "Complete onboarding to unlock Starter Access."
        case .unauthenticated:
            return "Authentication is required before using OneDone."
        }
    }

    private var ctaTitle: String {
        switch accessState {
        case .starter_expired, .trial_not_started:
            return "Start 14-day trial"
        case .trial_expired, .subscription_expired, .billing_issue:
            return "Activate subscription (mock)"
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            return "Access active"
        case .onboarding_required:
            return "Continue onboarding"
        case .unauthenticated:
            return "Sign in required"
        }
    }

    private var isCTAButtonDisabled: Bool {
        switch accessState {
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            return true
        case .starter_expired, .trial_not_started:
            return !appState.isTrialEligible
        case .billing_issue, .trial_expired, .subscription_expired:
            return false
        case .onboarding_required, .unauthenticated:
            return true
        }
    }

    private var secondaryLinks: some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
            Text("Restore Purchases")
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.primary)
                .onTapGesture {
                    handleRestorePurchases()
                }

            Text("Terms of Use")
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.primary)
                .onTapGesture {
                    linkFeedback = "Terms of Use is a mock link in this prototype."
                }

            Text("Privacy Policy")
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.primary)
                .onTapGesture {
                    linkFeedback = "Privacy Policy is a mock link in this prototype."
                }
        }
        .padding(.top, 4)
    }

    private func handleCTAAction() {
        switch accessState {
        case .starter_expired, .trial_not_started:
            appState.activateAppStoreTrial()
            if appState.canCreateNewTasks {
                onActivated?()
            } else {
                linkFeedback = "Starter Access must be fully completed before trial activation."
            }
        case .billing_issue, .trial_expired, .subscription_expired:
            appState.activateMockSubscription()
            onActivated?()
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            break
        case .onboarding_required, .unauthenticated:
            break
        }
    }

    private func handleRestorePurchases() {
        switch accessState {
        case .trial_expired, .subscription_expired, .billing_issue:
            appState.activateMockSubscription()
            linkFeedback = "Mock restore completed. Subscription is now active."
            onActivated?()
        case .starter_expired, .trial_not_started:
            linkFeedback = "No purchases to restore yet in this mock Starter state."
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            linkFeedback = "Access is already active."
        case .onboarding_required, .unauthenticated:
            linkFeedback = "Restore is unavailable until authentication and onboarding are complete."
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionGateView(appState: AppState(), accessState: .starter_expired)
    }
}
