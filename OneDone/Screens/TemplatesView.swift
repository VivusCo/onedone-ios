import SwiftUI
import Observation

struct TemplatesView: View {
    @Bindable var appState: AppState
    @State private var selectedTemplateForTask: TaskTemplate?
    @State private var showSubscriptionGate: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                Text(
                    appState.canCreateNewTasks
                        ? "Start with a familiar situation."
                        : "Creation is locked. Tap any template to open access options."
                )
                .font(OneDoneStyle.helperFont)
                .foregroundStyle(ODColor.textSecondary)

                if appState.templates.isEmpty {
                    ODCard(style: .muted) {
                        Text("No templates available right now.")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                } else {
                    VStack(spacing: OneDoneStyle.contentSpacing) {
                        ForEach(appState.templates) { template in
                            Button {
                                handleTemplateTap(template)
                            } label: {
                                templateRow(template)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(template.title)
                        }
                    }
                }

                Color.clear
                    .frame(height: OneDoneStyle.tabRootContentBottomClearance)
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
        .sheet(isPresented: $showSubscriptionGate) {
            SubscriptionGateView(
                appState: appState,
                accessState: appState.mockAccessState
            ) {
                showSubscriptionGate = false
            }
        }
        .oneDoneScreen()
    }

    private func templateRow(_ template: TaskTemplate) -> some View {
        ODCard(contentPadding: 14, style: .listRow) {
            HStack(spacing: OneDoneStyle.contentSpacing) {
                templateOrb(icon: templateIcon(for: template), tone: templateOrbTone(for: template))

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(OneDoneStyle.subheadlineFont.weight(.semibold))
                        .foregroundStyle(ODColor.textPrimary)
                        .lineLimit(1)

                    Text(templateSubtitle(for: template))
                        .font(OneDoneStyle.captionFont)
                        .foregroundStyle(ODColor.textSecondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ODColor.textTertiary)
            }
            .frame(minHeight: 62)
        }
    }

    private func templateOrb(icon: String, tone: TemplateOrbTone) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                .fill(ODColor.surfaceStrong.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                        .fill(tone.background.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OneDoneStyle.radius16, style: .continuous)
                        .stroke(ODColor.border.opacity(0.86), lineWidth: 0.85)
                )
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tone.foreground)
        }
    }

    private func templateIcon(for template: TaskTemplate) -> String {
        switch template.resolvedBackendTemplateID {
        case "cancel_subscription":
            return "wallet.pass"
        case "return_item":
            return "arrow.uturn.backward.circle"
        case "request_refund":
            return "arrow.counterclockwise.circle"
        case "understand_bill":
            return "doc.text"
        case "write_complaint":
            return "exclamationmark.bubble"
        case "reply_to_message":
            return "bubble.left.and.text.bubble.right"
        default:
            return "sparkles"
        }
    }

    private func templateSubtitle(for template: TaskTemplate) -> String {
        switch template.resolvedBackendTemplateID {
        case "cancel_subscription":
            return "Find where it started and what to do next."
        case "return_item":
            return "Prepare evidence and a clear message."
        case "request_refund":
            return "Ask clearly without overexplaining."
        case "understand_bill":
            return "Paste the bill text and break down charges."
        case "write_complaint":
            return "Firm, polite, and useful wording."
        case "reply_to_message":
            return "Draft a calm and respectful response."
        default:
            return template.focus
        }
    }

    private func templateOrbTone(for template: TaskTemplate) -> TemplateOrbTone {
        switch template.resolvedBackendTemplateID {
        case "request_refund":
            return .warm
        case "cancel_subscription", "reply_to_message", "understand_bill", "return_item", "write_complaint":
            return .primary
        default:
            return .neutral
        }
    }

    private func handleTemplateTap(_ template: TaskTemplate) {
        if appState.canCreateNewTasks {
            selectedTemplateForTask = template
            return
        }

        showSubscriptionGate = true
    }
}

private enum TemplateOrbTone {
    case primary
    case warm
    case neutral

    var background: Color {
        switch self {
        case .primary:
            return ODColor.primarySoft
        case .warm:
            return ODColor.statusWarningFill
        case .neutral:
            return ODColor.statusNeutralFill
        }
    }

    var foreground: Color {
        switch self {
        case .primary:
            return ODColor.accentPrimaryDeepGreen
        case .warm:
            return ODColor.accentWarmOrangeSoft
        case .neutral:
            return ODColor.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        TemplatesView(appState: AppState())
    }
}
