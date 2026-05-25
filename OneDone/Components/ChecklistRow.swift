import SwiftUI

struct ChecklistRow: View {
    let text: String
    var isChecked: Bool
    var isEnabled: Bool = true
    var detail: String? = nil
    var onToggle: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onToggle {
                Button(action: onToggle) {
                    rowContent
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            } else {
                rowContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
        .accessibilityValue(isChecked ? "Checked" : "Unchecked")
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: OneDoneStyle.space12) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isChecked ? ODColor.accentPrimaryDeepGreen : ODColor.textTertiary)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: OneDoneStyle.space4) {
                Text(text)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(isEnabled ? ODColor.textPrimary : ODColor.textTertiary)
                    .strikethrough(isChecked, color: ODColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let detail {
                    Text(detail)
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, OneDoneStyle.space12)
        .padding(.vertical, OneDoneStyle.space10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.radius12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.radius12, style: .continuous)
                        .fill(isChecked ? ODColor.statusSuccessFill.opacity(0.55) : ODColor.glassFillSecondary)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.radius12, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: 0.85)
        )
        .opacity(isEnabled ? 1.0 : 0.72)
    }
}

#Preview {
    VStack(spacing: OneDoneStyle.contentSpacing) {
        ChecklistRow(
            text: "Open Settings on your iPhone",
            isChecked: false,
            detail: "This is a visual-only foundation row in UI-01."
        )

        ChecklistRow(
            text: "Tap Subscriptions",
            isChecked: true
        )

        ChecklistRow(
            text: "Save confirmation",
            isChecked: false,
            isEnabled: false
        )
    }
    .padding(OneDoneStyle.screenPadding)
    .oneDoneScreen()
}
