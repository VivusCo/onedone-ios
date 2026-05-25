import SwiftUI
import Observation

struct SubscriptionGateView: View {
    @Bindable var appState: AppState
    let accessState: APIAccessState
    var onActivated: (() -> Void)? = nil

    @State private var linkFeedback: SubscriptionGateFeedback?
    @State private var isProcessing: Bool = false

    private let actionMaxWidth: CGFloat = 340

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

                        if isLockedState {
                            Divider()
                                .overlay(ODColor.border.opacity(0.5))
                                .padding(.vertical, 2)

                            Text("You can still view your existing tasks and task details while creation is locked.")
                                .font(OneDoneStyle.subheadlineFont)
                                .foregroundStyle(ODColor.textPrimary)
                        }
                    }
                }

                if isProcessing {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ProgressView()
                            .tint(ODColor.primary)
                        Text("Processing...")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                centeredAction {
                    ODPrimaryButton(
                        title: ctaTitle,
                        icon: "sparkles",
                        isDisabled: isCTAButtonDisabled || isProcessing
                    ) {
                        Task {
                            await handleCTAAction()
                        }
                    }
                }

                centeredAction {
                    ODSecondaryButton(
                        title: "Restore Purchases",
                        icon: "arrow.clockwise",
                        isDisabled: isProcessing
                    ) {
                        Task {
                            await handleRestorePurchases()
                        }
                    }
                }

                legalLinks

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
        .navigationTitle("Subscription")
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
            return "Creation is temporarily locked while billing is resolved."
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

    private var isLockedState: Bool {
        switch accessState {
        case .starter_expired, .trial_not_started, .billing_issue, .trial_expired, .subscription_expired:
            return true
        case .starter_active, .trial_active, .subscription_active, .subscription_cancelled_active, .grace_period, .onboarding_required, .unauthenticated:
            return false
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

    private var legalLinks: some View {
        VStack(spacing: OneDoneStyle.tightSpacing) {
            Button {
                linkFeedback = SubscriptionGateFeedback(
                    kind: .info,
                    message: "Terms of Use is a placeholder link in this prototype.",
                    shouldCloseGate: false
                )
            } label: {
                Text("Terms of Use")
                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                    .foregroundStyle(ODColor.primary)
                    .underline()
            }
            .buttonStyle(.plain)

            Button {
                linkFeedback = SubscriptionGateFeedback(
                    kind: .info,
                    message: "Privacy Policy is a placeholder link in this prototype.",
                    shouldCloseGate: false
                )
            } label: {
                Text("Privacy Policy")
                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                    .foregroundStyle(ODColor.primary)
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, OneDoneStyle.space4)
    }

    private func centeredAction<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            Spacer(minLength: 0)
            content()
                .frame(maxWidth: actionMaxWidth)
            Spacer(minLength: 0)
        }
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
