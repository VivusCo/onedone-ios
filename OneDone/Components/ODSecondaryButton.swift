import SwiftUI

struct ODSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: OneDoneStyle.contentSpacing) {
                if let icon {
                    Image(systemName: icon)
                }

                Text(title)
                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
            }
            .foregroundStyle(isDisabled ? ODColor.textMuted : ODColor.primary)
            .padding(.vertical, OneDoneStyle.buttonVerticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 14)
            .background(
                RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
                    .fill(ODColor.surfaceStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
                    .stroke(isDisabled ? ODColor.border.opacity(0.6) : ODColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        ODSecondaryButton(title: "Back", icon: "chevron.left", fullWidth: false) {}
        ODSecondaryButton(title: "Open Task", icon: "arrow.right") {}
        ODSecondaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .oneDoneScreen()
}
