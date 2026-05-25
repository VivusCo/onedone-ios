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
                        .fill(.ultraThinMaterial)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle()
                                .fill(ODColor.backgroundWarm.opacity(0.98))
                        )
                        .overlay(
                            Circle()
                                .stroke(ODColor.glassBorder.opacity(0.95), lineWidth: 0.9)
                        )
                        .overlay(
                            Circle()
                                .stroke(ODColor.backgroundWarm.opacity(0.98), lineWidth: 4.5)
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
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.28), lineWidth: 0.9)
                        )
                        .overlay(alignment: .top) {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 26, height: 9)
                                .blur(radius: 4.5)
                                .offset(y: 7)
                        }
                        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 8)
                        .shadow(color: ODColor.accentPrimaryDeepGreen.opacity(0.22), radius: 4, x: 0, y: 3)

                    Image(systemName: "plus")
                        .font(.system(size: 23, weight: .regular))
                        .foregroundStyle(ODColor.accentPrimaryContrast)
                        .offset(y: -1)
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
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
