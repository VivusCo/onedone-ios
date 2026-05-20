import SwiftUI
import Observation

struct TemplatesView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(
                    title: "Templates",
                    subtitle: "Quick text starters"
                )

                ForEach(appState.templates) { template in
                    NavigationLink {
                        NewTaskView(appState: appState, prefilledPrompt: template.promptHint, selectedTemplate: template)
                    } label: {
                        ODCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(template.title)
                                    .font(.headline)
                                    .foregroundStyle(ODColor.textPrimary)

                                Text(template.promptHint)
                                    .font(.subheadline)
                                    .foregroundStyle(ODColor.textSecondary)
                                    .lineLimit(3)

                                Text("Focus: \(template.focus)")
                                    .font(.caption)
                                    .foregroundStyle(ODColor.primary)
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
