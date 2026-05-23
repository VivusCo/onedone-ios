import SwiftUI
import Observation

struct SubscriptionGateView: View {
    @Bindable var appState: AppState
    let accessState: APIAccessState
    var onActivated: (() -> Void)? = nil

    @State private var linkFeedback: SubscriptionGateFeedback?
    @State private var isProcessing: Bool = false

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
                    isDisabled: isCTAButtonDisabled || isProcessing
                ) {
                    Task {
                        await handleCTAAction()
                    }
                }

                secondaryLinks

                if isProcessing {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ProgressView()
                            .tint(ODColor.primary)
                        Text("Processing...")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                if let linkFeedback {
                    ODInfoBanner(
                        title: feedbackTitle(for: linkFeedback.kind),
                        message: linkFeedback.message,
                        icon: feedbackIcon(for: linkFeedback.kind),
                        tone: feedbackTone(for: linkFeedback.kind)
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
            return "Your trial has ended. Start your App Store subscription to continue creating new tasks."
        case .subscription_expired:
            return "Your subscription has ended. Renew access to continue creating new tasks."
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
            return "Start 14-day trial"
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
            return "Access active"
        case .onboarding_required:
            return "Continue onboarding"
        case .unauthenticated:
            return "Sign in required"
        }
    }

    private var isCTAButtonDisabled: Bool {
        if appState.shouldUseRemoteSubscriptionFlow {
            switch accessState {
            case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period:
                return true
            case .starter_expired, .trial_not_started, .billing_issue, .trial_expired, .subscription_expired:
                return false
            case .onboarding_required, .unauthenticated:
                return true
            }
        }

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
            Button {
                Task {
                    await handleRestorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                    .foregroundStyle(ODColor.primary)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            Text("Terms of Use")
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.primary)
                .onTapGesture {
                    linkFeedback = SubscriptionGateFeedback(
                        kind: .info,
                        message: "Terms of Use is a placeholder link in this prototype.",
                        shouldCloseGate: false
                    )
                }

            Text("Privacy Policy")
                .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                .foregroundStyle(ODColor.primary)
                .onTapGesture {
                    linkFeedback = SubscriptionGateFeedback(
                        kind: .info,
                        message: "Privacy Policy is a placeholder link in this prototype.",
                        shouldCloseGate: false
                    )
                }
        }
        .padding(.top, 4)
    }

    @MainActor
    private func handleCTAAction() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        let feedback = await appState.startSubscriptionFromGate(accessState: accessState)
        linkFeedback = feedback
        if feedback.shouldCloseGate {
            onActivated?()
        }
    }

    @MainActor
    private func handleRestorePurchases() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        let feedback = await appState.restorePurchasesFromGate(accessState: accessState)
        linkFeedback = feedback
        if feedback.shouldCloseGate {
            onActivated?()
        }
    }

    private func feedbackTitle(for kind: SubscriptionGateFeedbackKind) -> String {
        switch kind {
        case .success:
            return "Access updated"
        case .info:
            return "Update"
        case .warning:
            return "Could not complete action"
        case .requiresLogin:
            return "Login required"
        }
    }

    private func feedbackIcon(for kind: SubscriptionGateFeedbackKind) -> String {
        switch kind {
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .requiresLogin:
            return "person.crop.circle.badge.exclamationmark"
        }
    }

    private func feedbackTone(for kind: SubscriptionGateFeedbackKind) -> ODStatusTone {
        switch kind {
        case .success:
            return .success
        case .info:
            return .neutral
        case .warning, .requiresLogin:
            return .warning
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionGateView(appState: AppState(), accessState: .starter_expired)
    }
}
