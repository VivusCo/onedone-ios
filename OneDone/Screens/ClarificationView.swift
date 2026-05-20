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
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(
                    title: "Clarification",
                    subtitle: "One focused question"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(initialDraft.clarificationQuestion)
                            .font(.headline)
                            .foregroundStyle(ODColor.textPrimary)

                        TextField("Type your answer", text: $clarificationAnswer, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(ODColor.cardBorder, lineWidth: 1)
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
