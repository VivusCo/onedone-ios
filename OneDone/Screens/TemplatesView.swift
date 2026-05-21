import SwiftUI
import Observation

struct TemplatesView: View {
    @Bindable var appState: AppState
    @State private var selectedTemplateForTask: TaskTemplate?
    @State private var selectedTemplateForGate: TaskTemplate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Templates",
                    subtitle: "Quick text starters for common tasks"
                )

                ODInfoBanner(
                    title: "Text-first workflow",
                    message: "Paste the message, bill, or document text. Upload is not part of this MVP.",
                    icon: "text.alignleft"
                )

                ODStatusBadge(
                    title: appState.hasActiveTemplateAccess ? "Starter access active" : "Starter access ended",
                    tone: appState.hasActiveTemplateAccess ? .highlight : .warning
                )

                ForEach(appState.templates) { template in
                    Button {
                        handleTemplateTap(template)
                    } label: {
                        ODCard {
                            VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                                Text(template.title)
                                    .font(OneDoneStyle.cardTitleFont)
                                    .foregroundStyle(ODColor.textPrimary)

                                Text(template.promptHint)
                                    .font(OneDoneStyle.subheadlineFont)
                                    .foregroundStyle(ODColor.textSecondary)
                                    .lineLimit(3)

                                ODStatusBadge(title: "Focus: \(template.focus)", tone: .neutral)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedTemplateForTask) { template in
            NewTaskView(
                appState: appState,
                prefilledPrompt: template.promptHint,
                selectedTemplate: template
            )
        }
        .sheet(item: $selectedTemplateForGate) { template in
            trialGateSheet(template: template)
        }
        .oneDoneScreen()
    }

    private func handleTemplateTap(_ template: TaskTemplate) {
        if appState.hasActiveTemplateAccess {
            selectedTemplateForTask = template
            return
        }

        selectedTemplateForGate = template
    }

    private func trialGateSheet(template: TaskTemplate) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Trial required",
                    subtitle: "Starter Access has ended in this mock state"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Selected template")
                            .font(OneDoneStyle.captionFont.weight(.semibold))
                            .foregroundStyle(ODColor.primary)

                        Text(template.title)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text("Start your 14-day App Store trial to continue using templates.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODPrimaryButton(
                    title: appState.appStoreTrialActivated ? "Trial active" : "Start 14-day trial (mock)",
                    icon: "sparkles",
                    isDisabled: appState.appStoreTrialActivated || !appState.isTrialEligible
                ) {
                    appState.activateAppStoreTrial()
                    if appState.hasActiveTemplateAccess {
                        selectedTemplateForGate = nil
                    }
                }

                if !appState.isTrialEligible {
                    ODInfoBanner(
                        title: "Trial not available yet",
                        message: "Finish Starter Access days in Access screen to unlock the trial gate.",
                        icon: "info.circle.fill",
                        tone: .warning
                    )
                }

                ODSecondaryButton(title: "Close", icon: "xmark") {
                    selectedTemplateForGate = nil
                }

                Spacer()
            }
            .padding(OneDoneStyle.screenPadding)
            .oneDoneScreen()
        }
    }
}

#Preview {
    NavigationStack {
        TemplatesView(appState: AppState())
    }
}
