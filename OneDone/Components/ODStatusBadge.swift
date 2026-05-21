import SwiftUI

enum ODStatusTone {
    case neutral
    case highlight
    case success
    case warning

    var backgroundColor: Color {
        switch self {
        case .neutral:
            return ODColor.surfaceStrong
        case .highlight:
            return ODColor.primarySoft
        case .success:
            return ODColor.successSoft
        case .warning:
            return ODColor.warningSoft
        }
    }

    var textColor: Color {
        switch self {
        case .warning:
            return ODColor.textPrimary
        default:
            return ODColor.primary
        }
    }
}

struct ODStatusBadge: View {
    let title: String
    var tone: ODStatusTone = .neutral

    var body: some View {
        Text(title)
            .font(OneDoneStyle.captionFont.weight(.semibold))
            .foregroundStyle(tone.textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.backgroundColor)
            )
    }
}

#Preview {
    HStack {
        ODStatusBadge(title: "Starter access", tone: .highlight)
        ODStatusBadge(title: "Ready", tone: .success)
        ODStatusBadge(title: "Coming soon", tone: .warning)
    }
    .padding()
    .oneDoneScreen()
}
