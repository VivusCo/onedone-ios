import SwiftUI

struct ElevatedTaskTabButton: View {
    var title: String = "Task"
    var accessibilityLabel: String = "Create task"
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(ODColor.backgroundWarm.opacity(0.98))
                        .frame(width: 74, height: 74)
                        .overlay(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.74)
                        )
                        .overlay(
                            Circle()
                                .stroke(ODColor.glassBorder.opacity(0.96), lineWidth: 1.0)
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
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.30), lineWidth: 1.0)
                        )
                        .overlay(alignment: .top) {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 30, height: 11)
                                .blur(radius: 5.5)
                                .offset(y: 8.5)
                        }
                        .shadow(color: Color.black.opacity(0.13), radius: 13, x: 0, y: 9)
                        .shadow(color: ODColor.accentPrimaryDeepGreen.opacity(0.20), radius: 5, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(ODColor.accentPrimaryContrast)
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
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
