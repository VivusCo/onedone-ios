import SwiftUI

enum OneDoneStyle {
    // Spacing
    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let contentSpacing: CGFloat = 10
    static let tightSpacing: CGFloat = 8
    static let relaxedSpacing: CGFloat = 20

    // Shape
    static let cardCornerRadius: CGFloat = 20
    static let controlCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 14
    static let badgeCornerRadius: CGFloat = 999

    // Insets
    static let cardPadding: CGFloat = 18
    static let buttonVerticalPadding: CGFloat = 14
    static let controlHorizontalPadding: CGFloat = 12
    static let controlVerticalPadding: CGFloat = 10

    // Typography
    static let heroFont = Font.system(size: 38, weight: .bold, design: .rounded)
    static let sectionTitleFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let cardTitleFont = Font.system(.headline, design: .rounded)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let subheadlineFont = Font.system(.subheadline, design: .rounded)
    static let captionFont = Font.system(.footnote, design: .rounded)
}

extension View {
    func oneDoneScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(ODColor.background.ignoresSafeArea())
    }
}
