import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: OneDoneStyle.relaxedSpacing) {
            Spacer(minLength: 24)

            ODCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("OneDone")
                        .font(OneDoneStyle.heroFont)
                        .foregroundStyle(ODColor.primary)

                    Text("A warm, guided self-service assistant for finishing one meaningful task at a time.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)

                    HStack(spacing: OneDoneStyle.contentSpacing) {
                        Label("Text-first MVP", systemImage: "text.alignleft")
                        Label("Calm workflow", systemImage: "leaf.fill")
                    }
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)
                }
            }

            ODPrimaryButton(title: "Get Started", icon: "arrow.right") {
                onGetStarted()
            }

            Spacer()
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
