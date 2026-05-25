import SwiftUI

enum ODColor {
    // MARK: - Base Canvas (warm / calm)
    static let backgroundWarm = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let backgroundAccentRadialA = Color(red: 0.34, green: 0.58, blue: 0.45).opacity(0.22)
    static let backgroundAccentRadialB = Color(red: 0.90, green: 0.66, blue: 0.40).opacity(0.18)

    // MARK: - Glass Surfaces
    static let glassFillPrimary = Color.white.opacity(0.50)
    static let glassFillSecondary = Color.white.opacity(0.36)
    static let glassBorder = Color.white.opacity(0.62)
    static let glassShadow = Color.black.opacity(0.08)

    // MARK: - Semantic Brand Colors
    static let accentPrimaryDeepGreen = Color(red: 0.12, green: 0.37, blue: 0.25)
    static let accentPrimaryDeepGreenPressed = Color(red: 0.09, green: 0.31, blue: 0.21)
    static let accentWarmOrangeSoft = Color(red: 0.90, green: 0.65, blue: 0.38)
    static let accentPrimaryContrast = Color.white

    static let textPrimary = Color(red: 0.12, green: 0.17, blue: 0.14)
    static let textSecondary = Color(red: 0.34, green: 0.40, blue: 0.36)
    static let textTertiary = Color(red: 0.46, green: 0.50, blue: 0.45)

    static let border = Color(red: 0.83, green: 0.85, blue: 0.79)
    static let borderSoft = Color.white.opacity(0.58)

    // MARK: - Status Colors
    static let statusSuccessFill = Color(red: 0.84, green: 0.92, blue: 0.85)
    static let statusWarningFill = Color(red: 0.97, green: 0.90, blue: 0.78)
    static let statusNeutralFill = Color(red: 0.93, green: 0.93, blue: 0.89)
    static let statusLockedFill = Color(red: 0.89, green: 0.88, blue: 0.84)

    // MARK: - Backward-Compatible Aliases
    static let background = backgroundWarm
    static let surface = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let surfaceStrong = Color(red: 0.95, green: 0.94, blue: 0.90)
    static let primary = accentPrimaryDeepGreen
    static let primarySoft = Color(red: 0.80, green: 0.88, blue: 0.82)
    static let primaryContrast = accentPrimaryContrast
    static let textMuted = textTertiary
    static let successSoft = statusSuccessFill
    static let warningSoft = statusWarningFill
    static let infoSoft = Color(red: 0.86, green: 0.92, blue: 0.88)
    static let cardBackground = surface
    static let cardBorder = border
}

struct ODWarmRadialBackground: View {
    var body: some View {
        ZStack {
            ODColor.backgroundWarm

            RadialGradient(
                colors: [ODColor.backgroundAccentRadialA, .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .blendMode(.normal)

            RadialGradient(
                colors: [ODColor.backgroundAccentRadialB, .clear],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 380
            )
            .blendMode(.normal)
        }
        .ignoresSafeArea()
    }
}
