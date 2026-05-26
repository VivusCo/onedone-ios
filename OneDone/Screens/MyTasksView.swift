import SwiftUI
import Observation

struct MyTasksView: View {
    @Bindable var appState: AppState
    @State private var selectedFilter: MyTasksFilter = .all
    @State private var isLoadingRemoteTasks: Bool = false
    @State private var remoteLoadErrorMessage: String?
    @State private var hasTriggeredInitialRemoteLoad: Bool = false
    @State private var showCreateTask: Bool = false
    @State private var showSubscriptionGate: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "My Tasks",
                    subtitle: "Follow-through hub for active work"
                )

                if filteredAndSortedTasks.isEmpty {
                    IllustrationCard(
                        title: "Keep momentum",
                        subtitle: "Prioritized by what needs your attention first.",
                        variant: .focused,
                        minHeight: 118
                    )
                } else {
                    ODCard(contentPadding: 14, style: .muted) {
                        HStack(spacing: OneDoneStyle.tightSpacing) {
                            Text("Keep momentum")
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)
                            Spacer(minLength: OneDoneStyle.space8)
                            Text("\(filteredAndSortedTasks.count) in view")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

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

                    HStack {
                        Spacer(minLength: 0)
                        ODSecondaryButton(title: "Retry", icon: "arrow.clockwise", fullWidth: false) {
                            Task {
                                await refreshRemoteTasks(showLoading: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }

                if shouldShowRemoteLoadingState {
                    ODCard(style: .muted) {
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
                    if selectedFilter == .all {
                        VStack(spacing: OneDoneStyle.sectionSpacing) {
                            IllustrationCard(
                                title: "Nothing here yet",
                                subtitle: "Tap the Task button to turn one messy thing into a clear plan.",
                                variant: .calm,
                                minHeight: 118
                            )

                            ODCard(style: .muted) {
                                Text(emptyStateText)
                                    .font(OneDoneStyle.bodyFont)
                                    .foregroundStyle(ODColor.textSecondary)
                            }

                            HStack {
                                Spacer(minLength: 0)
                                ODPrimaryButton(title: "Create first task", icon: "sparkles") {
                                    handleEmptyStateCreateTap()
                                }
                                .frame(maxWidth: 260)
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ODCard(style: .muted) {
                            VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                                Text("No tasks in this view")
                                    .font(OneDoneStyle.cardTitleFont)
                                    .foregroundStyle(ODColor.textPrimary)

                                Text(emptyStateText)
                                    .font(OneDoneStyle.bodyFont)
                                    .foregroundStyle(ODColor.textSecondary)
                            }
                        }
                    }
                } else {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ForEach(filteredAndSortedTasks) { task in
                            NavigationLink {
                                TaskDetailView(appState: appState, taskID: task.id)
                            } label: {
                                TaskCard(
                                    title: task.title,
                                    category: task.category,
                                    statusTitle: task.status.displayTitle,
                                    statusTone: tone(for: task.status),
                                    scheduleText: scheduleText(for: task),
                                    nextStepPreview: task.currentNextStep,
                                    lastEventPreview: task.lastEventPreview,
                                    style: .muted
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Color.clear
                    .frame(height: OneDoneStyle.tabRootContentBottomClearance)
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("My Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showCreateTask) {
            NewTaskView(appState: appState, prefilledPrompt: nil)
        }
        .sheet(isPresented: $showSubscriptionGate) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showSubscriptionGate = false
            }
        }
        .oneDoneScreen()
        .refreshable {
            await refreshRemoteTasks(showLoading: false)
        }
        .task {
            await loadTasksIfNeeded()
        }
    }

    private var filterBar: some View {
        ODCard(contentPadding: 8, style: .muted) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: OneDoneStyle.tightSpacing) {
                    ForEach(MyTasksFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(
                                    selectedFilter == filter ? ODColor.primaryContrast : ODColor.textPrimary
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(selectedFilter == filter ? ODColor.primary : ODColor.glassFillSecondary)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(
                                            selectedFilter == filter ? ODColor.primary.opacity(0.0) : ODColor.glassBorder,
                                            lineWidth: 0.9
                                        )
                                )
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(filter.rawValue)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
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
                ? "No tasks yet. Create one from Task to get started."
                : "No tasks yet. Create one from Task."
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

    private func handleEmptyStateCreateTap() {
        if appState.canCreateNewTasks {
            showCreateTask = true
        } else {
            showSubscriptionGate = true
        }
    }
}

#Preview {
    NavigationStack {
        MyTasksView(appState: AppState())
    }
}
