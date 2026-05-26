import SwiftUI

struct StarterAccessIntroView: View {
    var showMockNotice: Bool = false
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ODSectionHeader(
                title: "Your first 3 days are open",
                subtitle: "Starter Access"
            )

            IllustrationCard(
                title: "Starter Access",
                subtitle: "Create tasks, draft replies, and set reminders with calm guidance.",
                variant: .focused,
                minHeight: 132
            )

            ODCard(style: .strong) {
                VStack(alignment: .leading, spacing: OneDoneStyle.space12) {
                    Text("What you can do now")
                        .font(OneDoneStyle.cardHeadlineFont)
                        .foregroundStyle(ODColor.textPrimary)

                    featureRow("Create and organize admin tasks")
                    featureRow("Generate clear reply drafts")
                    featureRow("Set follow-up reminders")

                    if showMockNotice {
                        ODInfoBanner(
                            title: "Preview data enabled",
                            message: "Sample tasks are shown in this session.",
                            icon: "checkmark.shield"
                        )
                    }
                }
            }

            HStack {
                Spacer(minLength: 0)
                ODPrimaryButton(title: "Start using OneDone", icon: "arrow.right", fullWidth: false) {
                    onContinue()
                }
                .frame(maxWidth: 260)
                Spacer(minLength: 0)
            }

            Spacer()
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: OneDoneStyle.space8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ODColor.accentPrimaryDeepGreen)

            Text(text)
                .font(OneDoneStyle.subheadlineFont)
                .foregroundStyle(ODColor.textSecondary)
        }
    }
}

#Preview {
    StarterAccessIntroView(showMockNotice: true, onContinue: {})
}
