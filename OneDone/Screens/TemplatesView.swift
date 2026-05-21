import SwiftUI
import Observation

struct TemplatesView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Templates",
                    subtitle: "Quick text starters"
                )

                ForEach(appState.templates) { template in
                    NavigationLink {
                        NewTaskView(appState: appState, prefilledPrompt: template.promptHint, selectedTemplate: template)
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
        .oneDoneScreen()
    }
}

#Preview {
    NavigationStack {
        TemplatesView(appState: AppState())
    }
}
