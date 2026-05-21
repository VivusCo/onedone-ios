import SwiftUI
import Observation

struct TemplatesView: View {
    @Bindable var appState: AppState
    @State private var selectedTemplateForTask: TaskTemplate?
    @State private var showSubscriptionGate: Bool = false

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
                    title: appState.canCreateNewTasks ? "Creation unlocked" : "Creation locked",
                    tone: appState.canCreateNewTasks ? .highlight : .warning
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

    private func handleTemplateTap(_ template: TaskTemplate) {
        if appState.canCreateNewTasks {
            selectedTemplateForTask = template
            return
        }

        showSubscriptionGate = true
    }
}

#Preview {
    NavigationStack {
        TemplatesView(appState: AppState())
    }
}
