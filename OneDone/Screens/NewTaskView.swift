import SwiftUI
import Observation

struct NewTaskView: View {
    @Bindable var appState: AppState
    let prefilledPrompt: String?
    var selectedTemplate: TaskTemplate? = nil

    @State private var prompt: String = ""
    @State private var draft: TaskDraft?
    @State private var showClarification: Bool = false
    @State private var taskResult: MockTask?
    @State private var showTaskResult: Bool = false
    @State private var showSubscriptionGate: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var submitErrorMessage: String?
    @State private var splitPreviewMessage: String?
    @State private var lastSubmission: AnalyzeSubmissionState?

    private struct AnalyzeSubmissionState: Equatable {
        let prompt: String
        let template: TaskTemplate?
        let idempotencyKey: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "New Task",
                    subtitle: "Describe one task in plain text"
                )

                if let selectedTemplate {
                    ODCard {
                        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                            Text("Template")
                                .font(OneDoneStyle.captionFont.weight(.semibold))
                                .foregroundStyle(ODColor.primary)
                            Text(selectedTemplate.title)
                                .font(OneDoneStyle.cardTitleFont)
                                .foregroundStyle(ODColor.textPrimary)
                            Text(selectedTemplate.focus)
                                .font(OneDoneStyle.subheadlineFont)
                                .foregroundStyle(ODColor.textSecondary)
                        }
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Task prompt")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        TextEditor(text: $prompt)
                            .font(OneDoneStyle.bodyFont)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                    .fill(ODColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                    .stroke(ODColor.border, lineWidth: 1)
                            )

                        ODComingSoonBadge(text: "Attachments coming soon")
                    }
                }

                ODPrimaryButton(
                    title: "Analyze Task",
                    icon: "arrow.right",
                    isDisabled: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
                ) {
                    guard appState.canCreateNewTasks else {
                        showSubscriptionGate = true
                        return
                    }

                    Task {
                        await submitTaskAnalysis(retryLast: false)
                    }
                }

                if isSubmitting {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ProgressView()
                            .tint(ODColor.primary)
                        Text("Analyzing task...")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let submitErrorMessage {
                    ODInfoBanner(
                        title: "Could not analyze task",
                        message: submitErrorMessage,
                        icon: "exclamationmark.triangle.fill",
                        tone: .warning
                    )

                    if lastSubmission != nil {
                        ODSecondaryButton(title: "Retry analysis", icon: "arrow.clockwise") {
                            Task {
                                await submitTaskAnalysis(retryLast: true)
                            }
                        }
                    }
                }

                if let splitPreviewMessage {
                    ODInfoBanner(
                        title: "Multiple tasks detected",
                        message: splitPreviewMessage,
                        icon: "list.bullet.rectangle",
                        tone: .neutral
                    )
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .sheet(isPresented: $showSubscriptionGate) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showSubscriptionGate = false
            }
        }
        .onAppear {
            if prompt.isEmpty {
                prompt = prefilledPrompt ?? ""
            }
        }
        .navigationDestination(isPresented: $showClarification) {
            if let draft {
                ClarificationView(appState: appState, initialDraft: draft)
            }
        }
        .navigationDestination(isPresented: $showTaskResult) {
            if let taskResult {
                TaskResultView(appState: appState, task: taskResult)
            }
        }
    }

    @MainActor
    private func submitTaskAnalysis(retryLast: Bool) async {
        guard !isSubmitting else { return }
        guard appState.canCreateNewTasks else {
            showSubscriptionGate = true
            return
        }

        let submission: AnalyzeSubmissionState

        if retryLast, let lastSubmission {
            submission = lastSubmission
        } else {
            let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPrompt.isEmpty else { return }

            submission = AnalyzeSubmissionState(
                prompt: trimmedPrompt,
                template: selectedTemplate,
                idempotencyKey: UUID().uuidString.lowercased()
            )
            lastSubmission = submission
        }

        submitErrorMessage = nil
        splitPreviewMessage = nil
        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            let analysisResult = try await appState.analyzeNewTask(
                prompt: submission.prompt,
                selectedTemplate: submission.template,
                idempotencyKey: submission.idempotencyKey
            )

            switch analysisResult {
            case let .clarification(clarificationDraft):
                draft = clarificationDraft
                showClarification = true
            case let .taskAnalysis(analyzedTask):
                taskResult = analyzedTask
                showTaskResult = true
            case let .splitPreview(message):
                splitPreviewMessage = message
            }
        } catch let analyzeError as AnalyzeTaskServiceError {
            handleAnalyzeError(analyzeError)
        } catch {
            submitErrorMessage = "Could not analyze this task right now. Please try again."
        }
    }

    @MainActor
    private func handleAnalyzeError(_ error: AnalyzeTaskServiceError) {
        switch error {
        case let .accessDenied(message):
            let normalized = message.lowercased()
            if normalized.contains("session") ||
                normalized.contains("log in") ||
                normalized.contains("unauthorized") {
                appState.authErrorMessage = "Your session expired. Please log in again."
                appState.phase = .auth
                return
            }
            submitErrorMessage = message
            showSubscriptionGate = true
        case let .rateLimited(message):
            submitErrorMessage = message
        default:
            submitErrorMessage = error.errorDescription ?? "Could not analyze this task right now. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        NewTaskView(appState: AppState(), prefilledPrompt: "Draft a follow-up for a product demo.")
    }
}
