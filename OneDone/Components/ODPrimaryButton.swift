import SwiftUI

struct ODPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDisabled ? ODColor.primary.opacity(0.45) : ODColor.primary)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        ODPrimaryButton(title: "Continue", icon: "arrow.right.circle.fill") {}
        ODPrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .oneDoneScreen()
}
