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
            ODSectionHeader(
                title: "Let's keep it simple",
                subtitle: progressText
            )

            ODCard(style: .strong) {
                VStack(alignment: .leading, spacing: OneDoneStyle.space12) {
                    HStack(spacing: OneDoneStyle.space8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ODColor.accentPrimaryDeepGreen)

                        Text(page.subtitle)
                            .font(OneDoneStyle.sectionLabelFont)
                            .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                    }

                    Text(page.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(ODColor.textPrimary)

                    Text(page.body)
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineSpacing(2)
                }
            }

            HStack(spacing: OneDoneStyle.contentSpacing) {
                ForEach(0..<max(1, totalSteps), id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? ODColor.primary.opacity(0.85) : ODColor.primary.opacity(0.28))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: OneDoneStyle.contentSpacing) {
                if canGoBack {
                    ODSecondaryButton(title: "Back", icon: "chevron.left", isDisabled: isSubmitting, fullWidth: false) {
                        onBack()
                    }
                    .frame(width: 120)
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
                        .font(OneDoneStyle.helperFont)
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
        page: OnboardingPage(title: "One task at a time", subtitle: "Guided self-service", body: "Focus on one real task at a time."),
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
