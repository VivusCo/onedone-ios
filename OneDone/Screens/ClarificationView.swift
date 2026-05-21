import SwiftUI
import Observation

struct ClarificationView: View {
    @Bindable var appState: AppState
    let initialDraft: TaskDraft

    @State private var clarificationAnswer: String = ""
    @State private var preparedDraft: TaskDraft?
    @State private var showDraftReply: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Clarification",
                    subtitle: "One focused question"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text(initialDraft.clarificationQuestion)
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        ODTextField(
                            label: "Your answer",
                            placeholder: "Type your answer",
                            text: $clarificationAnswer
                        )
                    }
                }

                ODPrimaryButton(
                    title: "Generate Draft Reply",
                    icon: "doc.text.fill"
                ) {
                    preparedDraft = MockRepository.applyClarification(answer: clarificationAnswer, to: initialDraft)
                    showDraftReply = true
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Clarification")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
        .navigationDestination(isPresented: $showDraftReply) {
            if let preparedDraft {
                DraftReplyView(appState: appState, draft: preparedDraft)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClarificationView(
            appState: AppState(),
            initialDraft: MockRepository.makeDraft(prompt: "Write a respectful follow-up", template: nil)
        )
    }
}
