import SwiftUI

struct ODTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
            Text(label)
                .font(OneDoneStyle.subheadlineFont.weight(.medium))
                .foregroundStyle(ODColor.textPrimary)

            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
                .padding(.vertical, OneDoneStyle.controlVerticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                        .fill(ODColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                        .stroke(ODColor.border, lineWidth: 1)
                )
        }
    }
}
