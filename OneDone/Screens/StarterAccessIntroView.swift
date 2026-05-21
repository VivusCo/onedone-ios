import SwiftUI

struct StarterAccessIntroView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ODSectionHeader(title: "Starter Access", subtitle: "Your first 3 days")

            ODCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start simple")
                        .font(OneDoneStyle.cardTitleFont)
                        .foregroundStyle(ODColor.primary)

                    Text("After onboarding, you unlock 3-day Starter Access. Once it is complete, the App Store 14-day trial becomes available.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)

                    ODInfoBanner(
                        title: "Mock prototype",
                        message: "This version uses local mock state only.",
                        icon: "checkmark.shield"
                    )
                }
            }

            ODPrimaryButton(title: "Continue", icon: "arrow.right") {
                onContinue()
            }

            Spacer()
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }
}

#Preview {
    StarterAccessIntroView(onContinue: {})
}
