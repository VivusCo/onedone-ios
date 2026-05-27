import SwiftUI

enum ODStatusTone {
    case neutral
    case highlight
    case success
    case warning
    case locked

    var backgroundColor: Color {
        switch self {
        case .neutral:
            return ODColor.statusNeutralFill
        case .highlight:
            return ODColor.primarySoft
        case .success:
            return ODColor.statusSuccessFill
        case .warning:
            return ODColor.statusWarningFill
        case .locked:
            return ODColor.statusLockedFill
        }
    }

    var textColor: Color {
        switch self {
        case .highlight:
            return ODColor.accentPrimaryDeepGreen
        case .success:
            return ODColor.accentPrimaryDeepGreen
        case .warning:
            return ODColor.textPrimary
        case .neutral:
            return ODColor.textSecondary
        case .locked:
            return ODColor.textSecondary
        }
    }
}

struct ODStatusBadge: View {
    enum Style {
        case glass
        case listRow
    }

    let title: String
    var tone: ODStatusTone = .neutral
    var style: Style = .glass

    var body: some View {
        let borderColor: Color = {
            switch style {
            case .glass:
                return ODColor.glassBorder.opacity(0.9)
            case .listRow:
                return ODColor.border.opacity(0.88)
            }
        }()

        let backgroundFill: AnyShapeStyle = {
            switch style {
            case .glass:
                return AnyShapeStyle(.ultraThinMaterial)
            case .listRow:
                return AnyShapeStyle(ODColor.surfaceStrong.opacity(0.96))
            }
        }()

        let toneOpacity: Double = {
            switch style {
            case .glass:
                return 0.95
            case .listRow:
                return 0.9
            }
        }()

        Text(title)
            .font(OneDoneStyle.badgeFont)
            .foregroundStyle(tone.textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .allowsTightening(true)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(tone.backgroundColor.opacity(toneOpacity))
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 0.8)
            )
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(title)
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            ODStatusBadge(title: "Starter access", tone: .highlight)
            ODStatusBadge(title: "Ready", tone: .success)
            ODStatusBadge(title: "Coming soon", tone: .warning)
        }

        HStack {
            ODStatusBadge(title: "Locked", tone: .locked)
            ODStatusBadge(title: "Waiting for reply", tone: .neutral, style: .listRow)
        }
    }
    .padding()
    .oneDoneScreen()
}
