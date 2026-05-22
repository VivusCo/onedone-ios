import SwiftUI

struct StarterAccessIntroView: View {
    var showMockNotice: Bool = false
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ODSectionHeader(title: "Starter Access", subtitle: "Your first 3 days")

            ODCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your first 3 days are open.")
                        .font(OneDoneStyle.cardTitleFont)
                        .foregroundStyle(ODColor.primary)

                    Text("Try OneDone with real tasks. After 3 days, start your 14-day App Store trial to keep going.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)

                    if showMockNotice {
                        ODInfoBanner(
                            title: "Mock prototype",
                            message: "This version uses local mock state only.",
                            icon: "checkmark.shield"
                        )
                    }
                }
            }

            ODPrimaryButton(title: "Start using OneDone", icon: "arrow.right") {
                onContinue()
            }

            Spacer()
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }
}

#Preview {
    StarterAccessIntroView(showMockNotice: true, onContinue: {})
}
