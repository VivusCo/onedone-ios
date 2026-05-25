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
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(title)
                    .font(OneDoneStyle.buttonFont)
                    .lineLimit(1)
            }
            .foregroundStyle(isDisabled ? ODColor.textTertiary : ODColor.accentPrimaryDeepGreen)
            .padding(.vertical, OneDoneStyle.buttonVerticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 14)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(.isButton)
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
                    .fill(ODColor.glassFillSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
                    .stroke(isDisabled ? ODColor.border.opacity(0.6) : ODColor.glassBorder, lineWidth: 1)
            )
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
