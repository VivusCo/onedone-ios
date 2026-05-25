import SwiftUI

struct ODInfoBanner: View {
    let title: String
    let message: String
    var icon: String = "info.circle.fill"
    var tone: ODStatusTone = .highlight

    var body: some View {
        HStack(alignment: .top, spacing: OneDoneStyle.contentSpacing) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 24, height: 24)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconForeground)
            }
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
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                        .fill(tone.backgroundColor.opacity(0.72))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: 0.9)
        )
        .shadow(color: ODColor.glassShadow.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private var iconBackground: Color {
        switch tone {
        case .warning:
            return ODColor.statusWarningFill
        case .success:
            return ODColor.statusSuccessFill
        case .locked:
            return ODColor.statusLockedFill
        case .neutral:
            return ODColor.statusNeutralFill
        case .highlight:
            return ODColor.primarySoft
        }
    }

    private var iconForeground: Color {
        switch tone {
        case .warning:
            return ODColor.accentWarmOrangeSoft
        case .success:
            return ODColor.accentPrimaryDeepGreen
        case .locked, .neutral:
            return ODColor.textSecondary
        case .highlight:
            return ODColor.accentPrimaryDeepGreen
        }
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
