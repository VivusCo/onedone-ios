import SwiftUI

struct ElevatedTaskTabButton: View {
    var title: String = "Task"
    var accessibilityLabel: String = "Create task"
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 76, height: 76)
                        .overlay(
                            Circle()
                                .fill(ODColor.glassFillPrimary.opacity(0.92))
                        )
                        .overlay(
                            Circle()
                                .stroke(ODColor.glassBorder.opacity(0.96), lineWidth: 1.05)
                        )

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
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.34), lineWidth: 1)
                        )
                        .overlay(alignment: .top) {
                            Circle()
                                .fill(Color.white.opacity(0.24))
                                .frame(width: 28, height: 10)
                                .blur(radius: 5)
                                .offset(y: 8)
                        }
                        .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 9)
                        .shadow(color: ODColor.accentPrimaryDeepGreen.opacity(0.22), radius: 6, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ODColor.accentPrimaryContrast)
                }

                Text(title)
                    .font(OneDoneStyle.captionFont.weight(.semibold))
                    .foregroundStyle(ODColor.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.top, 4)
            .padding(.bottom, 2)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(ODColor.glassFillSecondary.opacity(0.88))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ODColor.glassBorder.opacity(0.86), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.62 : 1.0)
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
