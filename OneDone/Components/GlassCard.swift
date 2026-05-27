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
            return ODColor.glassFillPrimary
        case .strong:
            return ODColor.glassFillPrimary.opacity(0.85)
        case .muted:
            return ODColor.glassFillSecondary
        case .warning:
            return ODColor.statusWarningFill.opacity(0.45)
        case .listRow:
            return ODColor.glassFillPrimary.opacity(0.68)
        }
    }

    var borderColor: Color {
        switch self {
        case .warning:
            return ODColor.accentWarmOrangeSoft.opacity(0.65)
        case .listRow:
            return ODColor.border.opacity(0.92)
        default:
            return ODColor.glassBorder
        }
    }

    var usesMaterialBase: Bool {
        switch self {
        case .listRow:
            return false
        default:
            return true
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
            return Color.black.opacity(0.03)
        default:
            return ODColor.glassShadow
        }
    }

    var shadowRadiusMultiplier: CGFloat {
        switch self {
        case .listRow:
            return 0.25
        default:
            return 0.8
        }
    }

    var shadowYOffsetMultiplier: CGFloat {
        switch self {
        case .listRow:
            return 0.2
        default:
            return 0.8
        }
    }

    var extraSurfaceGlowOpacity: Double {
        switch self {
        case .listRow:
            return 0.07
        default:
            return 0.08
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
        let baseFill = style.usesMaterialBase
            ? AnyShapeStyle(.ultraThinMaterial)
            : AnyShapeStyle(ODColor.surfaceStrong.opacity(0.94))

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
                        .stroke(Color.white.opacity(OneDoneStyle.glassHighlightOpacity * 0.72), lineWidth: 0.55)
                        .padding(0.5)
                        .blendMode(.screen)
                }
            }
            .shadow(
                color: includeShadow ? style.shadowColor : .clear,
                radius: OneDoneStyle.glassShadowRadius * style.shadowRadiusMultiplier,
                x: 0,
                y: OneDoneStyle.glassShadowYOffset * style.shadowYOffsetMultiplier
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
