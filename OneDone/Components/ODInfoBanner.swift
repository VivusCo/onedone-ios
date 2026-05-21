import SwiftUI

struct ODInfoBanner: View {
    let title: String
    let message: String
    var icon: String = "info.circle.fill"
    var tone: ODStatusTone = .highlight

    var body: some View {
        HStack(alignment: .top, spacing: OneDoneStyle.contentSpacing) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tone.textColor)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                    .foregroundStyle(ODColor.textPrimary)

                Text(message)
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .fill(tone.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .stroke(ODColor.border.opacity(0.7), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        ODInfoBanner(
            title: "Local mock data",
            message: "This prototype currently uses local-only state and UI responses."
        )
        ODInfoBanner(
            title: "Trial gate",
            message: "14-day App Store trial appears after Starter Access completes.",
            icon: "sparkles",
            tone: .success
        )
    }
    .padding()
    .oneDoneScreen()
}
