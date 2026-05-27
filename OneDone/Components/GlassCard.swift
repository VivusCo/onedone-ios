import SwiftUI

enum GlassCardStyle {
    case `default`
    case strong
    case muted
    case warning
    case listRow

    var tint: Color {
        switch self {
        case .default:
            return ODColor.glassFillPrimary.opacity(0.48)
        case .strong:
            return ODColor.glassFillPrimary.opacity(0.62)
        case .muted:
            return ODColor.glassFillSecondary.opacity(0.58)
        case .warning:
            return ODColor.statusWarningFill.opacity(0.42)
        case .listRow:
            return ODColor.glassFillPrimary.opacity(0.58)
        }
    }

    var borderColor: Color {
        switch self {
        case .default, .strong, .muted:
            return ODColor.borderCard.opacity(0.92)
        case .warning:
            return ODColor.accentWarmOrangeSoft.opacity(0.65)
        case .listRow:
            return ODColor.border.opacity(0.92)
        }
    }

    var usesMaterialBase: Bool {
        false
    }

    var baseColor: Color {
        switch self {
        case .default:
            return ODColor.surfacePanel.opacity(0.97)
        case .strong:
            return ODColor.surfacePanelElevated.opacity(0.98)
        case .muted:
            return ODColor.surfacePanel.opacity(0.96)
        case .warning:
            return ODColor.surfacePanelElevated.opacity(0.97)
        case .listRow:
            return ODColor.surfaceStrong.opacity(0.94)
        }
    }

    var showsTopHighlight: Bool {
        switch self {
        case .listRow:
            return false
        default:
            return true
        }
    }

    var shadowColor: Color {
        switch self {
        case .listRow:
            return ODColor.shadowSubtle
        default:
            return ODColor.shadowSoft
        }
    }

    var shadowRadiusMultiplier: CGFloat {
        switch self {
        case .strong:
            return 0.9
        case .default, .warning:
            return 0.65
        case .muted:
            return 0.55
        case .listRow:
            return 0.24
        }
    }

    var shadowYOffsetMultiplier: CGFloat {
        switch self {
        case .strong:
            return 0.9
        case .default, .warning:
            return 0.7
        case .muted:
            return 0.6
        case .listRow:
            return 0.25
        }
    }

    var extraSurfaceGlowOpacity: Double {
        switch self {
        case .strong:
            return 0.075
        case .default:
            return 0.06
        case .muted:
            return 0.05
        case .warning:
            return 0.045
        case .listRow:
            return 0.07
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
        let baseFill = AnyShapeStyle(style.baseColor)

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(baseFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(style.tint)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(style.extraSurfaceGlowOpacity))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(style.borderColor.opacity(style == .listRow ? 1 : 0.9), lineWidth: OneDoneStyle.glassBorderWidth)
            )
            .overlay(alignment: .topLeading) {
                if style.showsTopHighlight {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(OneDoneStyle.glassHighlightOpacity * 0.45), lineWidth: 0.5)
                        .padding(0.5)
                        .blendMode(.screen)
                }
            }
            .shadow(
                color: includeShadow ? style.shadowColor : .clear,
                radius: OneDoneStyle.cardShadowRadius * style.shadowRadiusMultiplier,
                x: 0,
                y: OneDoneStyle.cardShadowYOffset * style.shadowYOffsetMultiplier
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

            GlassCard(style: .listRow) {
                Text("List row variant")
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textPrimary)
            }
        }
        .padding(OneDoneStyle.screenPadding)
    }
    .oneDoneScreen()
}
