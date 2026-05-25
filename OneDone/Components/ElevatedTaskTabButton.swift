import SwiftUI

struct ElevatedTaskTabButton: View {
    var title: String = "Task"
    var accessibilityLabel: String = "Create task"
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ODColor.accentPrimaryDeepGreen,
                                    ODColor.accentPrimaryDeepGreenPressed
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.26), lineWidth: 1)
                        )
                        .shadow(color: ODColor.glassShadow.opacity(0.95), radius: 14, x: 0, y: 8)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ODColor.accentPrimaryContrast)
                }

                Text(title)
                    .font(OneDoneStyle.captionFont.weight(.semibold))
                    .foregroundStyle(ODColor.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(ODColor.glassBorder.opacity(0.9), lineWidth: 0.85)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens task creation")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack {
        Spacer()

        ElevatedTaskTabButton(title: "Task", accessibilityLabel: "Create task") {}
            .padding(.bottom, 20)
    }
    .padding()
    .oneDoneScreen()
}
