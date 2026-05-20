import SwiftUI

struct ODCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: OneDoneStyle.cardCornerRadius, style: .continuous)
                    .fill(ODColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.cardCornerRadius, style: .continuous)
                    .stroke(ODColor.cardBorder, lineWidth: 1)
            )
    }
}

#Preview {
    ODCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card title")
                .font(.headline)
            Text("This is a calm, rounded card style used across the prototype.")
                .foregroundStyle(ODColor.textSecondary)
        }
    }
    .padding()
    .oneDoneScreen()
}
