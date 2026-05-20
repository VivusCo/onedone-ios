import SwiftUI

enum OneDoneStyle {
    static let screenPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 20
}

extension View {
    func oneDoneScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(ODColor.background.ignoresSafeArea())
    }
}
