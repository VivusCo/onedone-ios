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
            if isSubmitting {
                analyzingStateBlock
                    .padding(OneDoneStyle.screenPadding)
            } else {
                composeTaskBlock
                    .padding(OneDoneStyle.screenPadding)
            }
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

    private var composeTaskBlock: some View {
        VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
            IllustrationCard(
                title: "Text-first MVP",
                subtitle: "Paste message, bill, or policy text. Attachments and OCR stay coming soon.",
                variant: .focused,
                minHeight: 126
            )

            ODCard(style: .default) {
                VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                    Text("Task description")
                        .font(OneDoneStyle.cardTitleFont)
                        .foregroundStyle(ODColor.textPrimary)

                    TextEditor(text: $prompt)
                        .font(OneDoneStyle.bodyFont)
                        .frame(minHeight: 240)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                                        .fill(ODColor.glassFillSecondary)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: OneDoneStyle.radius20, style: .continuous)
                                .stroke(ODColor.glassBorder, lineWidth: 0.9)
                        )
                        .overlay(alignment: .topLeading) {
                            if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("What do you need to deal with?")
                                    .font(OneDoneStyle.bodyFont)
                                    .foregroundStyle(ODColor.textTertiary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                            }
                        }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: OneDoneStyle.tightSpacing) {
                            if let selectedTemplate {
                                metadataChip(title: selectedTemplate.title, tone: .highlight)
                            }
                            metadataChip(title: "Optional deadline")
                            metadataChip(title: "Auto category")
                        }
                        .padding(.horizontal, 2)
                    }

                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ODComingSoonBadge(text: "Attachments/OCR coming soon")
                        Text("Paste text only in MVP")
                            .font(OneDoneStyle.captionFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }
            }

            HStack {
                Spacer(minLength: 0)
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
                .frame(maxWidth: 260)
                Spacer(minLength: 0)
            }

            if let submitErrorMessage {
                ODInfoBanner(
                    title: "Could not analyze task",
                    message: submitErrorMessage,
                    icon: "exclamationmark.triangle.fill",
                    tone: .warning
                )

                if lastSubmission != nil {
                    HStack {
                        Spacer(minLength: 0)
                        ODSecondaryButton(title: "Retry analysis", icon: "arrow.clockwise") {
                            Task {
                                await submitTaskAnalysis(retryLast: true)
                            }
                        }
                        .frame(maxWidth: 260)
                        Spacer(minLength: 0)
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
    }

    private var analyzingStateBlock: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            Spacer(minLength: 50)

            ZStack {
                Circle()
                    .fill(ODColor.accentPrimaryDeepGreen.opacity(0.20))
                    .frame(width: 116, height: 116)
                    .blur(radius: 14)

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(ODColor.glassFillPrimary.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(ODColor.glassBorder, lineWidth: 0.9)
                    )
                    .frame(width: 112, height: 112)
                    .shadow(color: ODColor.glassShadow.opacity(0.75), radius: 16, x: 0, y: 8)

                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(ODColor.accentPrimaryDeepGreen)
            }

            VStack(spacing: OneDoneStyle.tightSpacing) {
                Text("Finding the next step")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(ODColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("If anything important is missing, OneDone will ask one clear question.")
                    .font(OneDoneStyle.subheadlineFont)
                    .foregroundStyle(ODColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            ProgressView()
                .tint(ODColor.accentPrimaryDeepGreen)
                .padding(.top, OneDoneStyle.space4)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, minHeight: 560)
    }

    private func metadataChip(title: String, tone: ODStatusTone = .neutral) -> some View {
        ODStatusBadge(title: title, tone: tone)
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
