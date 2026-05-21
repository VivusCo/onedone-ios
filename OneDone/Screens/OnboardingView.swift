import SwiftUI

struct OnboardingView: View {
    let page: OnboardingPage
    let progressText: String
    let canGoBack: Bool
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
                Circle().fill(ODColor.primary.opacity(0.85)).frame(width: 7, height: 7)
                Circle().fill(ODColor.primary.opacity(0.45)).frame(width: 7, height: 7)
                Circle().fill(ODColor.primary.opacity(0.25)).frame(width: 7, height: 7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: OneDoneStyle.contentSpacing) {
                if canGoBack {
                    ODSecondaryButton(title: "Back", icon: "chevron.left", fullWidth: false) {
                        onBack()
                    }
                }

                ODPrimaryButton(title: "Next", icon: "arrow.right.circle.fill") {
                    onNext()
                }
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
        canGoBack: false,
        onBack: {},
        onNext: {}
    )
}
