import SwiftUI

enum ODColor {
    // MARK: - Base Canvas (warm / calm)
    static let backgroundWarm = Color(red: 0.978, green: 0.974, blue: 0.960)
    static let backgroundAccentRadialA = Color(red: 0.14, green: 0.44, blue: 0.37).opacity(0.16)
    static let backgroundAccentRadialB = Color(red: 0.93, green: 0.69, blue: 0.46).opacity(0.14)
    static let backgroundAccentRadialC = Color(red: 1.00, green: 0.99, blue: 0.97).opacity(0.26)

    // MARK: - Glass Surfaces
    static let glassFillPrimary = Color(red: 1.00, green: 0.99, blue: 0.97).opacity(0.56)
    static let glassFillSecondary = Color(red: 1.00, green: 0.99, blue: 0.97).opacity(0.42)
    static let glassBorder = Color.white.opacity(0.52)
    static let glassShadow = Color.black.opacity(0.065)

    // MARK: - Semantic Brand Colors
    static let accentPrimaryDeepGreen = Color(red: 0.12, green: 0.37, blue: 0.25)
    static let accentPrimaryDeepGreenPressed = Color(red: 0.09, green: 0.31, blue: 0.21)
    static let accentWarmOrangeSoft = Color(red: 0.90, green: 0.65, blue: 0.38)
    static let accentPrimaryContrast = Color.white

    static let textPrimary = Color(red: 0.12, green: 0.17, blue: 0.14)
    static let textSecondary = Color(red: 0.34, green: 0.40, blue: 0.36)
    static let textTertiary = Color(red: 0.46, green: 0.50, blue: 0.45)

    static let border = Color(red: 0.86, green: 0.87, blue: 0.82)
    static let borderSoft = Color.white.opacity(0.5)

    // MARK: - Status Colors
    static let statusSuccessFill = Color(red: 0.84, green: 0.92, blue: 0.85)
    static let statusWarningFill = Color(red: 0.97, green: 0.90, blue: 0.78)
    static let statusNeutralFill = Color(red: 0.93, green: 0.93, blue: 0.89)
    static let statusLockedFill = Color(red: 0.89, green: 0.88, blue: 0.84)

    // MARK: - Backward-Compatible Aliases
    static let background = backgroundWarm
    static let surface = Color(red: 0.989, green: 0.984, blue: 0.972)
    static let surfaceStrong = Color(red: 0.962, green: 0.955, blue: 0.936)
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

            LinearGradient(
                colors: [
                    Color.white.opacity(0.52),
                    Color.white.opacity(0.30),
                    Color.white.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.normal)

            RadialGradient(
                colors: [ODColor.backgroundAccentRadialA, .clear],
                center: UnitPoint(x: 0.12, y: 0.08),
                startRadius: 12,
                endRadius: 340
            )
            .blendMode(.normal)

            RadialGradient(
                colors: [ODColor.backgroundAccentRadialB, .clear],
                center: UnitPoint(x: 0.88, y: 0.12),
                startRadius: 20,
                endRadius: 320
            )
            .blendMode(.normal)

            RadialGradient(
                colors: [ODColor.backgroundAccentRadialC, .clear],
                center: UnitPoint(x: 0.55, y: 0.84),
                startRadius: 50,
                endRadius: 450
            )
            .blendMode(.normal)
        }
        .ignoresSafeArea()
    }
}
