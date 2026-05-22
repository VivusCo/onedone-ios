import SwiftUI
import Observation

struct MyTasksView: View {
    @Bindable var appState: AppState
    @State private var selectedFilter: MyTasksFilter = .all
    @State private var isLoadingRemoteTasks: Bool = false
    @State private var remoteLoadErrorMessage: String?
    @State private var hasTriggeredInitialRemoteLoad: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "My Tasks",
                    subtitle: "Follow-through hub for active tasks"
                )

                ODInfoBanner(
                    title: "Stay in motion",
                    message: "Prioritized by what needs your attention first.",
                    icon: "checklist",
                    tone: .highlight
                )

                filterBar

                if let remoteLoadErrorMessage {
                    if appState.shouldUseRemoteTaskActions && !appState.tasks.isEmpty {
                        ODInfoBanner(
                            title: "Showing last saved data",
                            message: "Showing last saved data. Pull to refresh.",
                            icon: "arrow.triangle.2.circlepath",
                            tone: .neutral
                        )
                    } else {
                        ODInfoBanner(
                            title: "Could not load tasks",
                            message: remoteLoadErrorMessage,
                            icon: "exclamationmark.triangle.fill",
                            tone: .warning
                        )
                    }

                    ODSecondaryButton(title: "Retry", icon: "arrow.clockwise") {
                        Task {
                            await refreshRemoteTasks(showLoading: true)
                        }
                    }
                }

                if shouldShowRemoteLoadingState {
                    ODCard {
                        HStack(spacing: OneDoneStyle.tightSpacing) {
                            ProgressView()
                                .tint(ODColor.primary)
                            Text("Loading tasks...")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if filteredAndSortedTasks.isEmpty {
                    ODCard {
                        Text(emptyStateText)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                } else {
                    ForEach(filteredAndSortedTasks) { task in
                        NavigationLink {
                            TaskDetailView(appState: appState, taskID: task.id)
                        } label: {
                            taskCard(task)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("My Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .refreshable {
            await refreshRemoteTasks(showLoading: false)
        }
        .task {
            await loadTasksIfNeeded()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: OneDoneStyle.tightSpacing) {
                ForEach(MyTasksFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(OneDoneStyle.captionFont.weight(.semibold))
                            .foregroundStyle(
                                selectedFilter == filter ? ODColor.primaryContrast : ODColor.textPrimary
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selectedFilter == filter ? ODColor.primary : ODColor.surfaceStrong)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(ODColor.border, lineWidth: selectedFilter == filter ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func taskCard(_ task: MockTask) -> some View {
        ODCard {
            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                HStack(alignment: .top, spacing: OneDoneStyle.tightSpacing) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)
                            .lineLimit(2)

                        Text(task.category)
                            .font(OneDoneStyle.captionFont.weight(.medium))
                            .foregroundStyle(ODColor.textMuted)
                    }

                    Spacer()

                    ODStatusBadge(
                        title: task.status.displayTitle,
                        tone: tone(for: task.status)
                    )
                }

                if let scheduleText = scheduleText(for: task) {
                    Label(scheduleText, systemImage: "calendar")
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    previewLine(title: "Next", text: task.currentNextStep)
                    previewLine(title: "Last", text: task.lastEventPreview)
                }
            }
        }
    }

    @ViewBuilder
    private func previewLine(title: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(title):")
                .font(OneDoneStyle.captionFont.weight(.semibold))
                .foregroundStyle(ODColor.textSecondary)
            Text(text)
                .font(OneDoneStyle.captionFont)
                .foregroundStyle(ODColor.textSecondary)
                .lineLimit(1)
        }
    }

    private var filteredAndSortedTasks: [MockTask] {
        let filtered = appState.tasks.filter { selectedFilter.matches($0.status) }
        return filtered.sorted { lhs, rhs in
            if lhs.status.sortPriority != rhs.status.sortPriority {
                return lhs.status.sortPriority < rhs.status.sortPriority
            }

            let lhsDate = lhs.reminderDate ?? lhs.dueDate
            let rhsDate = rhs.reminderDate ?? rhs.dueDate

            switch (lhsDate, rhsDate) {
            case let (left?, right?):
                if left != right {
                    return left < right
                }
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                break
            }

            return lhs.createdAt > rhs.createdAt
        }
    }

    private var emptyStateText: String {
        if selectedFilter == .all {
            return appState.shouldUseRemoteTaskActions
                ? "No tasks yet. Create one from Home to get started."
                : "No tasks yet. Create one from Home."
        }
        return "No tasks in \(selectedFilter.rawValue) right now."
    }

    private var shouldShowRemoteLoadingState: Bool {
        appState.shouldUseRemoteTaskActions && isLoadingRemoteTasks && appState.tasks.isEmpty
    }

    private func scheduleText(for task: MockTask) -> String? {
        if let reminderDate = task.reminderDate {
            return "Reminder \(dateFormatter.string(from: reminderDate))"
        }
        if let dueDate = task.dueDate {
            return "Due \(dateFormatter.string(from: dueDate))"
        }
        return nil
    }

    private var dateFormatter: DateFormatter {
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

    @MainActor
    private func loadTasksIfNeeded() async {
        guard appState.shouldUseRemoteTaskActions else {
            remoteLoadErrorMessage = nil
            return
        }

        guard !hasTriggeredInitialRemoteLoad else { return }
        hasTriggeredInitialRemoteLoad = true
        await refreshRemoteTasks(showLoading: true)
    }

    @MainActor
    private func refreshRemoteTasks(showLoading: Bool) async {
        guard appState.shouldUseRemoteTaskActions else {
            remoteLoadErrorMessage = nil
            isLoadingRemoteTasks = false
            return
        }

        if showLoading {
            isLoadingRemoteTasks = true
        }

        let loadError = await appState.refreshTasksFromRemote()
        remoteLoadErrorMessage = loadError
        isLoadingRemoteTasks = false
    }
}

#Preview {
    NavigationStack {
        MyTasksView(appState: AppState())
    }
}
