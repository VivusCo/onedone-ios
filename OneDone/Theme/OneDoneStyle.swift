import SwiftUI

enum OneDoneStyle {
    // MARK: - Spacing
    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space10: CGFloat = 10
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32

    // Backward-compatible spacing aliases
    static let screenPadding: CGFloat = space20
    static let sectionSpacing: CGFloat = space16
    static let contentSpacing: CGFloat = space10
    static let tightSpacing: CGFloat = space8
    static let relaxedSpacing: CGFloat = space20
    // Extra scroll runway for root tab screens so final content can lift above the custom bottom nav.
    static let tabRootContentBottomClearance: CGFloat = 72

    // MARK: - Radius
    static let radius8: CGFloat = 8
    static let radius12: CGFloat = 12
    static let radius16: CGFloat = 16
    static let radius20: CGFloat = 20
    static let radius24: CGFloat = 24
    static let radiusPill: CGFloat = 999

    // Backward-compatible radius aliases
    static let cardCornerRadius: CGFloat = radius20
    static let controlCornerRadius: CGFloat = radius12
    static let buttonCornerRadius: CGFloat = 14
    static let badgeCornerRadius: CGFloat = radiusPill

    // MARK: - Insets
    static let cardPadding: CGFloat = 18
    static let buttonVerticalPadding: CGFloat = 14
    static let controlHorizontalPadding: CGFloat = 12
    static let controlVerticalPadding: CGFloat = 10

    // MARK: - Glass Surface
    static let glassBorderWidth: CGFloat = 1
    static let glassShadowRadius: CGFloat = 18
    static let glassShadowYOffset: CGFloat = 8
    static let glassHighlightOpacity: CGFloat = 0.25

    // MARK: - Typography
    static let heroFont = Font.system(size: 38, weight: .bold, design: .rounded)
    static let sectionTitleFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let cardTitleFont = Font.system(.headline, design: .rounded)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let subheadlineFont = Font.system(.subheadline, design: .rounded)
    static let captionFont = Font.system(.footnote, design: .rounded)
    static let badgeFont = Font.system(.caption, design: .rounded).weight(.semibold)
    static let buttonFont = Font.system(.callout, design: .rounded).weight(.semibold)
}

extension View {
    func oneDoneScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(ODWarmRadialBackground())
    }

    func oneDoneGlassStroke(cornerRadius: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: OneDoneStyle.glassBorderWidth)
        )
    }
}
