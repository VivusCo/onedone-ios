import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            Spacer(minLength: OneDoneStyle.space24)

            IllustrationCard(
                title: "Life admin, less messy",
                subtitle: "Turn everyday admin tasks into clear next steps.",
                variant: .calm,
                minHeight: 132
            )

            ODCard(style: .strong) {
                VStack(alignment: .leading, spacing: OneDoneStyle.space12) {
                    Text("OneDone")
                        .font(OneDoneStyle.heroTitleFont)
                        .foregroundStyle(ODColor.primary)

                    Text("A warm, guided self-service assistant for finishing one meaningful task at a time.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)

                    HStack(spacing: OneDoneStyle.space8) {
                        featurePill("Start with text", icon: "text.alignleft")
                        featurePill("Calm workflow", icon: "leaf.fill")
                    }
                    .padding(.top, OneDoneStyle.space4)
                }
            }

            HStack {
                Spacer(minLength: 0)
                ODPrimaryButton(title: "Get Started", icon: "arrow.right", fullWidth: false) {
                    onGetStarted()
                }
                .frame(maxWidth: 260)
                Spacer(minLength: 0)
            }

            Spacer(minLength: OneDoneStyle.space8)

            Text("A guided self-service assistant. No autonomous actions.")
                .font(OneDoneStyle.captionFont)
                .foregroundStyle(ODColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }

    private func featurePill(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(OneDoneStyle.captionFont.weight(.semibold))
            .foregroundStyle(ODColor.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, OneDoneStyle.space10)
            .padding(.vertical, OneDoneStyle.space8)
            .background(
                Capsule(style: .continuous)
                    .fill(ODColor.glassFillSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ODColor.glassBorder.opacity(0.85), lineWidth: 0.8)
            )
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
