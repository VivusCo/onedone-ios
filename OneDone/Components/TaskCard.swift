import SwiftUI

struct TaskCard: View {
    let title: String
    var category: String? = nil
    var statusTitle: String
    var statusTone: ODStatusTone = .neutral
    var scheduleText: String? = nil
    var nextStepPreview: String? = nil
    var lastEventPreview: String? = nil
    var style: GlassCardStyle = .default
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    cardBody
                }
                .buttonStyle(.plain)
            } else {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        GlassCard(style: style, contentPadding: 14) {
            VStack(alignment: .leading, spacing: OneDoneStyle.space10) {
                HStack(alignment: .top, spacing: OneDoneStyle.space8) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.space4) {
                        Text(title)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .layoutPriority(1)

                        if let category {
                            Text(category)
                                .font(OneDoneStyle.captionFont.weight(.medium))
                                .foregroundStyle(ODColor.textTertiary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer(minLength: 8)

                    ODStatusBadge(title: statusTitle, tone: statusTone)
                        .layoutPriority(2)
                }

                if let scheduleText {
                    Label(scheduleText, systemImage: "calendar")
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if let nextStepPreview {
                    previewRow(prefix: "Next", text: nextStepPreview)
                }

                if let lastEventPreview {
                    previewRow(prefix: "Last", text: lastEventPreview)
                }
            }
        }
    }

    private func previewRow(prefix: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(prefix):")
                .font(OneDoneStyle.captionFont.weight(.semibold))
                .foregroundStyle(ODColor.textSecondary)

            Text(text)
                .font(OneDoneStyle.captionFont)
                .foregroundStyle(ODColor.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

#Preview {
    VStack(spacing: OneDoneStyle.sectionSpacing) {
        TaskCard(
            title: "Cancel subscription billed through App Store",
            category: "Subscriptions",
            statusTitle: "Needs Clarification",
            statusTone: .warning,
            scheduleText: "Due tomorrow",
            nextStepPreview: "Confirm where the charge appears.",
            lastEventPreview: "Asked for billing source clarification."
        )

        TaskCard(
            title: "Request refund for delayed package",
            category: "Orders",
            statusTitle: "Waiting for Reply",
            statusTone: .neutral,
            scheduleText: "Reminder Jun 20",
            nextStepPreview: "Wait for merchant response.",
            lastEventPreview: "Marked message as sent.",
            style: .muted
        )
    }
    .padding(OneDoneStyle.screenPadding)
    .oneDoneScreen()
}
