import SwiftUI

struct ODCard<Content: View>: View {
    var contentPadding: CGFloat = OneDoneStyle.cardPadding
    private let content: Content

    init(contentPadding: CGFloat = OneDoneStyle.cardPadding, @ViewBuilder content: () -> Content) {
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: OneDoneStyle.cardCornerRadius, style: .continuous)
                    .fill(ODColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.cardCornerRadius, style: .continuous)
                    .stroke(ODColor.border, lineWidth: 1)
            )
    }
}

#Preview {
    ODCard {
        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
            Text("Card title")
                .font(OneDoneStyle.cardTitleFont)
            Text("This is a calm, rounded card style used across the prototype.")
                .font(OneDoneStyle.subheadlineFont)
                .foregroundStyle(ODColor.textSecondary)
        }
    }
    .padding()
    .oneDoneScreen()
}
