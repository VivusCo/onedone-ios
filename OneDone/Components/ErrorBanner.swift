import SwiftUI

enum ErrorBannerTone {
    case info
    case warning
    case critical
    case success

    var icon: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }

    var titleColor: Color {
        switch self {
        case .critical:
            return ODColor.textPrimary
        default:
            return ODColor.textPrimary
        }
    }

    var fill: Color {
        switch self {
        case .info:
            return ODColor.statusNeutralFill
        case .warning:
            return ODColor.statusWarningFill
        case .critical:
            return Color(red: 0.97, green: 0.86, blue: 0.82)
        case .success:
            return ODColor.statusSuccessFill
        }
    }

    var iconColor: Color {
        switch self {
        case .info:
            return ODColor.textSecondary
        case .warning:
            return ODColor.accentWarmOrangeSoft
        case .critical:
            return Color(red: 0.65, green: 0.22, blue: 0.17)
        case .success:
            return ODColor.accentPrimaryDeepGreen
        }
    }
}

struct ErrorBanner: View {
    let title: String
    let message: String
    var tone: ErrorBannerTone = .warning
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: OneDoneStyle.contentSpacing) {
            Image(systemName: tone.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tone.iconColor)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: OneDoneStyle.space4) {
                Text(title)
                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                    .foregroundStyle(tone.titleColor)

                Text(message)
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)

                if let actionTitle, let action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(OneDoneStyle.captionFont.weight(.semibold))
                            .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                        .fill(tone.fill.opacity(0.85))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: 0.9)
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ErrorBanner(
                title: "Could not load tasks",
                message: "Please check your connection and try again.",
                tone: .warning,
                actionTitle: "Retry"
            ) {}

            ErrorBanner(
                title: "Session expired",
                message: "Please log in again to continue.",
                tone: .critical,
                actionTitle: "Log in"
            ) {}

            ErrorBanner(
                title: "Saved",
                message: "Your reminder was synced successfully.",
                tone: .success
            )
        }
        .padding(OneDoneStyle.screenPadding)
    }
    .oneDoneScreen()
}
