import SwiftUI

struct ODLoadingStateCard: View {
    var title: String = "Working on it"
    var message: String = "Please wait while OneDone prepares the next step."
    var symbol: String = "sparkles"
    var minHeight: CGFloat = 240

    var body: some View {
        GlassCard(style: .strong) {
            VStack(spacing: OneDoneStyle.sectionSpacing) {
                ZStack {
                    Circle()
                        .fill(ODColor.accentPrimaryDeepGreen.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .blur(radius: 14)

                    RoundedRectangle(cornerRadius: OneDoneStyle.radius24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: OneDoneStyle.radius24, style: .continuous)
                                .fill(ODColor.glassFillPrimary.opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: OneDoneStyle.radius24, style: .continuous)
                                .stroke(ODColor.glassBorder.opacity(0.9), lineWidth: 0.9)
                        )
                        .frame(width: 102, height: 102)

                    Image(systemName: symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                }

                VStack(spacing: OneDoneStyle.space8) {
                    Text(title)
                        .font(OneDoneStyle.cardHeadlineFont)
                        .foregroundStyle(ODColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(OneDoneStyle.helperFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                ProgressView()
                    .tint(ODColor.accentPrimaryDeepGreen)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.vertical, OneDoneStyle.space4)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ODLoadingStateCard(
                title: "Finding the next step",
                message: "If anything important is missing, OneDone will ask one clear question.",
                symbol: "sparkles"
            )

            ODLoadingStateCard(
                title: "Refreshing tasks",
                message: "Pulling your latest updates.",
                symbol: "arrow.triangle.2.circlepath"
            )
        }
        .padding(OneDoneStyle.screenPadding)
    }
    .oneDoneScreen()
}
