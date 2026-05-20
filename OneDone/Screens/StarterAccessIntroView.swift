import SwiftUI

struct StarterAccessIntroView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ODSectionHeader(title: "Starter Access", subtitle: "Your first 3 days")

            ODCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start simple")
                        .font(.headline)
                        .foregroundStyle(ODColor.primary)

                    Text("After onboarding, you unlock 3-day Starter Access. Once it is complete, the App Store 14-day trial becomes available.")
                        .foregroundStyle(ODColor.textSecondary)

                    Text("This prototype uses local mock state only.")
                        .font(.footnote)
                        .foregroundStyle(ODColor.textSecondary)
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
