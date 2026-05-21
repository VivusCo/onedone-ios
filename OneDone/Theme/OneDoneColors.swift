import SwiftUI

enum ODColor {
    // Core palette
    static let background = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let surface = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let surfaceStrong = Color(red: 0.95, green: 0.94, blue: 0.90)

    static let primary = Color(red: 0.11, green: 0.35, blue: 0.24)
    static let primarySoft = Color(red: 0.80, green: 0.88, blue: 0.82)
    static let primaryContrast = Color.white

    static let border = Color(red: 0.86, green: 0.87, blue: 0.82)

    static let textPrimary = Color(red: 0.12, green: 0.17, blue: 0.14)
    static let textSecondary = Color(red: 0.34, green: 0.40, blue: 0.36)
    static let textMuted = Color(red: 0.46, green: 0.50, blue: 0.45)

    // Semantic accents
    static let successSoft = Color(red: 0.84, green: 0.92, blue: 0.85)
    static let warningSoft = Color(red: 0.96, green: 0.90, blue: 0.78)
    static let infoSoft = Color(red: 0.86, green: 0.92, blue: 0.88)

    // Backward-compatible aliases
    static let cardBackground = surface
    static let cardBorder = border
}
