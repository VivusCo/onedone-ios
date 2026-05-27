import SwiftUI

struct ElevatedTaskTabButton: View {
    var title: String = "Task"
    var accessibilityLabel: String = "Create task"
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                ZStack {
                    Circle()
                        .fill(ODColor.surfacePanelElevated.opacity(0.99))
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .fill(ODColor.glassFillSecondary.opacity(0.58))
                        )
                        .overlay(
                            Circle()
                                .stroke(ODColor.borderCard.opacity(0.9), lineWidth: 0.9)
                        )
                        .overlay(
                            Circle()
                                .stroke(ODColor.backgroundWarm.opacity(0.99), lineWidth: 4.2)
                        )
                        .shadow(color: ODColor.shadowSubtle, radius: OneDoneStyle.panelShadowRadius * 0.7, x: 0, y: OneDoneStyle.panelShadowYOffset * 0.7)

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
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.28), lineWidth: 0.9)
                        )
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 24, height: 7)
                                .offset(y: 8)
                        }
                        .shadow(color: Color.black.opacity(0.12), radius: 9, x: 0, y: 6)
                        .shadow(color: ODColor.accentPrimaryDeepGreen.opacity(0.18), radius: 3, x: 0, y: 2)

                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(ODColor.accentPrimaryContrast)
                        .offset(y: -0.3)
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                    .lineLimit(1)
                    .offset(y: -7)
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
