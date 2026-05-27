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
                        .fill(ODColor.surfaceField)
                        .overlay(
                            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                .fill(ODColor.glassFillSecondary.opacity(0.66))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                        .stroke(ODColor.borderField.opacity(0.9), lineWidth: 0.9)
                )
        }
    }
}
