import SwiftUI

struct OnboardingView: View {
    let page: OnboardingPage
    let progressText: String
    let currentStep: Int
    let totalSteps: Int
    let canGoBack: Bool
    let isSubmitting: Bool
    let submitErrorMessage: String?
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ODSectionHeader(title: "Onboarding", subtitle: progressText)

            ODCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text(page.subtitle.uppercased())
                        .font(OneDoneStyle.captionFont.weight(.semibold))
                        .foregroundStyle(ODColor.primary)

                    Text(page.title)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(ODColor.textPrimary)

                    Text(page.body)
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                }
            }

            HStack(spacing: OneDoneStyle.contentSpacing) {
                ForEach(0..<max(1, totalSteps), id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? ODColor.primary.opacity(0.85) : ODColor.primary.opacity(0.28))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: OneDoneStyle.contentSpacing) {
                if canGoBack {
                    ODSecondaryButton(title: "Back", icon: "chevron.left", isDisabled: isSubmitting, fullWidth: false) {
                        onBack()
                    }
                }

                ODPrimaryButton(
                    title: isSubmitting ? "Finishing..." : "Next",
                    icon: "arrow.right.circle.fill",
                    isDisabled: isSubmitting
                ) {
                    onNext()
                }
            }

            if isSubmitting {
                HStack(spacing: OneDoneStyle.tightSpacing) {
                    ProgressView()
                        .tint(ODColor.primary)
                    Text("Completing onboarding...")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let submitErrorMessage {
                ODInfoBanner(
                    title: "Could not continue",
                    message: submitErrorMessage,
                    icon: "exclamationmark.triangle.fill",
                    tone: .warning
                )
            }

            Spacer()
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }
}

#Preview {
    OnboardingView(
        page: OnboardingPage(title: "OneDone keeps it simple", subtitle: "Guided self-service", body: "Focus on one real task at a time."),
        progressText: "Step 1 of 3",
        currentStep: 0,
        totalSteps: 3,
        canGoBack: false,
        isSubmitting: false,
        submitErrorMessage: nil,
        onBack: {},
        onNext: {}
    )
}
