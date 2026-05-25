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
            VStack(alignment: .leading, spacing: OneDoneStyle.space12) {
                HStack(alignment: .top, spacing: OneDoneStyle.space8) {
                    Text(title)
                        .font(OneDoneStyle.cardTitleFont.weight(.bold))
                        .foregroundStyle(ODColor.textPrimary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .layoutPriority(1)

                    Spacer(minLength: 8)

                    ODStatusBadge(title: statusTitle, tone: statusTone)
                        .layoutPriority(3)
                }

                if let nextStepPreview {
                    Text(nextStepPreview)
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                }

                metadataRow
            }
        }
    }

    @ViewBuilder
    private var metadataRow: some View {
        let primaryMeta = scheduleText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? scheduleText
            : category
        let secondaryMeta = lastEventPreview?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? lastEventPreview
            : nil

        if primaryMeta != nil || secondaryMeta != nil {
            HStack(alignment: .firstTextBaseline, spacing: OneDoneStyle.space8) {
                if let primaryMeta {
                    if scheduleText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Label(primaryMeta, systemImage: "calendar")
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        Text(primaryMeta)
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer(minLength: OneDoneStyle.space8)

                if let secondaryMeta {
                    Text(secondaryMeta)
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ODColor.textMuted)
            }
            .padding(.top, OneDoneStyle.space8)
            .overlay(alignment: .top) {
                Divider()
                    .overlay(ODColor.glassBorder.opacity(0.6))
            }
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
