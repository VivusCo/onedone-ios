import SwiftUI

struct ODPrimaryButton: View {
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
            .foregroundStyle(ODColor.accentPrimaryContrast)
            .padding(.vertical, OneDoneStyle.buttonVerticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 14)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous))
            .shadow(color: isDisabled ? .clear : ODColor.glassShadow.opacity(0.9), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(.isButton)
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isDisabled
                        ? [ODColor.accentPrimaryDeepGreen.opacity(0.45), ODColor.accentPrimaryDeepGreen.opacity(0.40)]
                        : [ODColor.accentPrimaryDeepGreen, ODColor.accentPrimaryDeepGreenPressed],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: OneDoneStyle.buttonCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(isDisabled ? 0.0 : 0.22), lineWidth: 0.75)
            )
    }
}

#Preview {
    VStack(spacing: 12) {
        ODPrimaryButton(title: "Continue", icon: "arrow.right.circle.fill") {}
        ODPrimaryButton(title: "Inline", icon: "checkmark", fullWidth: false) {}
        ODPrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .oneDoneScreen()
}
