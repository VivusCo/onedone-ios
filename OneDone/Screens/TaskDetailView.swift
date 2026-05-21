import SwiftUI

struct TaskDetailView: View {
    let task: MockTask

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Task Detail",
                    subtitle: "Keep momentum with clear next steps"
                )

                headerSection
                statusSection
                nextStepSection
                checklistSection
                latestOutputSection

                if let replyDraft = task.replyDraft, !replyDraft.isEmpty {
                    replyDraftSection(replyDraft)
                }

                reminderSection
                timelineSection
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }

    private var headerSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Header")

                Text(task.title)
                    .font(OneDoneStyle.cardTitleFont)
                    .foregroundStyle(ODColor.textPrimary)

                Text(task.category)
                    .font(OneDoneStyle.captionFont.weight(.medium))
                    .foregroundStyle(ODColor.textMuted)

                Text("Created \(dateTimeFormatter.string(from: task.createdAt))")
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    private var statusSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Status")

                HStack {
                    ODStatusBadge(title: task.status.displayTitle, tone: tone(for: task.status))
                    Spacer()
                    if let dateLabel = dueOrReminderText {
                        Text(dateLabel)
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }
            }
        }
    }

    private var nextStepSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Current next step")
                Text(task.currentNextStep)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    private var checklistSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Checklist")

                if task.actionPlan.isEmpty {
                    Text("No checklist items yet.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    ForEach(Array(task.actionPlan.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.primary)
                                .padding(.top, 2)
                            Text(step)
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var latestOutputSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Latest AI output")
                Text(task.latestAIOutput)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func replyDraftSection(_ replyDraft: String) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Reply draft")
                Text(replyDraft)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }

    private var reminderSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                cardTitle("Reminder")

                if let reminderDate = task.reminderDate {
                    Label("Reminder set for \(dateTimeFormatter.string(from: reminderDate))", systemImage: "bell")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else if let dueDate = task.dueDate {
                    Label("Due on \(dateTimeFormatter.string(from: dueDate))", systemImage: "calendar")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    Text("No reminder set yet.")
                        .font(OneDoneStyle.subheadlineFont)
                        .foregroundStyle(ODColor.textSecondary)
                }
            }
        }
    }

    private var timelineSection: some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                cardTitle("Timeline")

                if compactTimeline.isEmpty {
                    Text("No timeline events yet.")
                        .font(OneDoneStyle.bodyFont)
                        .foregroundStyle(ODColor.textSecondary)
                } else {
                    ForEach(compactTimeline) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(entry.title)
                                    .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                                    .foregroundStyle(ODColor.textPrimary)
                                Spacer()
                                Text(dateFormatter.string(from: entry.date))
                                    .font(OneDoneStyle.captionFont)
                                    .foregroundStyle(ODColor.textMuted)
                            }
                            Text(entry.detail)
                                .font(OneDoneStyle.captionFont)
                                .foregroundStyle(ODColor.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private var compactTimeline: [TaskTimelineEntry] {
        task.timeline
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    private var dueOrReminderText: String? {
        if let reminderDate = task.reminderDate {
            return "Reminder \(dateFormatter.string(from: reminderDate))"
        }
        if let dueDate = task.dueDate {
            return "Due \(dateFormatter.string(from: dueDate))"
        }
        return nil
    }

    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(OneDoneStyle.captionFont.weight(.semibold))
            .foregroundStyle(ODColor.primary)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func tone(for status: TaskStatus) -> ODStatusTone {
        switch status {
        case .followUpNeeded:
            return .warning
        case .dueSoon:
            return .warning
        case .needsClarification:
            return .warning
        case .waitingForReply:
            return .neutral
        case .inProgress:
            return .neutral
        case .new, .ready, .draft:
            return .highlight
        case .postponed:
            return .neutral
        case .done:
            return .success
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: MockRepository.seedTasks[0])
    }
}
