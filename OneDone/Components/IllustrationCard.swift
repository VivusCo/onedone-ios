import SwiftUI

enum IllustrationCardVariant {
    case calm
    case optimistic
    case focused

    var primaryTint: Color {
        switch self {
        case .calm:
            return ODColor.accentPrimaryDeepGreen.opacity(0.28)
        case .optimistic:
            return ODColor.accentWarmOrangeSoft.opacity(0.30)
        case .focused:
            return ODColor.accentPrimaryDeepGreenPressed.opacity(0.28)
        }
    }

    var secondaryTint: Color {
        switch self {
        case .calm:
            return ODColor.accentWarmOrangeSoft.opacity(0.20)
        case .optimistic:
            return ODColor.accentPrimaryDeepGreen.opacity(0.24)
        case .focused:
            return ODColor.accentWarmOrangeSoft.opacity(0.18)
        }
    }
}

struct IllustrationCard: View {
    var title: String? = nil
    var subtitle: String? = nil
    var variant: IllustrationCardVariant = .calm
    var minHeight: CGFloat = 148

    var body: some View {
        GlassCard {
            HStack(spacing: OneDoneStyle.space16) {
                ZStack {
                    Circle()
                        .fill(variant.primaryTint)
                        .frame(width: 92, height: 92)
                        .offset(x: -6, y: -6)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(variant.secondaryTint)
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(-18))
                        .offset(x: 16, y: 14)

                    Circle()
                        .stroke(ODColor.glassBorder.opacity(0.9), lineWidth: 1.2)
                        .frame(width: 58, height: 58)
                        .offset(x: 12, y: -14)
                }
                .frame(width: 116, height: 92)

                VStack(alignment: .leading, spacing: OneDoneStyle.space8) {
                    if let title {
                        Text(title)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: minHeight)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            IllustrationCard(
                title: "One small thing, done.",
                subtitle: "Focus on one task and keep calm momentum.",
                variant: .calm
            )

            IllustrationCard(
                title: "Quick support",
                subtitle: "Use templates and guided steps to move forward.",
                variant: .optimistic
            )

            IllustrationCard(
                title: "Follow-through",
                subtitle: "Track reminders and next steps clearly.",
                variant: .focused
            )
        }
        .padding(OneDoneStyle.screenPadding)
    }
    .oneDoneScreen()
}
