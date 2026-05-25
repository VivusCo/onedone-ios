import SwiftUI

enum GlassCardStyle {
    case `default`
    case strong
    case muted
    case warning

    var tint: Color {
        switch self {
        case .default:
            return ODColor.glassFillPrimary
        case .strong:
            return ODColor.glassFillPrimary.opacity(0.85)
        case .muted:
            return ODColor.glassFillSecondary
        case .warning:
            return ODColor.statusWarningFill.opacity(0.45)
        }
    }

    var borderColor: Color {
        switch self {
        case .warning:
            return ODColor.accentWarmOrangeSoft.opacity(0.65)
        default:
            return ODColor.glassBorder
        }
    }
}

struct GlassCard<Content: View>: View {
    var style: GlassCardStyle = .default
    var contentPadding: CGFloat = OneDoneStyle.cardPadding
    var cornerRadius: CGFloat = OneDoneStyle.cardCornerRadius
    var includeShadow: Bool = true

    private let content: Content

    init(
        style: GlassCardStyle = .default,
        contentPadding: CGFloat = OneDoneStyle.cardPadding,
        cornerRadius: CGFloat = OneDoneStyle.cardCornerRadius,
        includeShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.contentPadding = contentPadding
        self.cornerRadius = cornerRadius
        self.includeShadow = includeShadow
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(style.tint)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(style.borderColor, lineWidth: OneDoneStyle.glassBorderWidth)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(OneDoneStyle.glassHighlightOpacity), lineWidth: 0.5)
                    .padding(0.5)
                    .blendMode(.screen)
            }
            .shadow(
                color: includeShadow ? ODColor.glassShadow : .clear,
                radius: OneDoneStyle.glassShadowRadius,
                x: 0,
                y: OneDoneStyle.glassShadowYOffset
            )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            GlassCard {
                VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                    Text("Default Glass Card")
                        .font(OneDoneStyle.cardTitleFont)
                        .foregroundStyle(ODColor.textPrimary)
                    Text("Warm, calm translucent surface for primary content.")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                }
            }

            GlassCard(style: .strong) {
                Text("Strong variant")
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textPrimary)
            }

            GlassCard(style: .muted) {
                Text("Muted variant")
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }

            GlassCard(style: .warning) {
                Text("Warning variant")
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textPrimary)
            }
        }
        .padding(OneDoneStyle.screenPadding)
    }
    .oneDoneScreen()
}
