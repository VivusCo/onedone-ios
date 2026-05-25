import SwiftUI

struct ODCard<Content: View>: View {
    var contentPadding: CGFloat = OneDoneStyle.cardPadding
    var style: GlassCardStyle = .default
    private let content: Content

    init(
        contentPadding: CGFloat = OneDoneStyle.cardPadding,
        style: GlassCardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.contentPadding = contentPadding
        self.style = style
        self.content = content()
    }

    var body: some View {
        GlassCard(style: style, contentPadding: contentPadding) {
            content
        }
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
