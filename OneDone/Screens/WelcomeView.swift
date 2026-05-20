import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            ODCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("OneDone")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(ODColor.primary)

                    Text("A warm, guided self-service assistant for finishing one meaningful task at a time.")
                        .font(.body)
                        .foregroundStyle(ODColor.textSecondary)

                    HStack(spacing: 10) {
                        Label("Text-first MVP", systemImage: "text.alignleft")
                        Label("Calm workflow", systemImage: "leaf.fill")
                    }
                    .font(.footnote)
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
