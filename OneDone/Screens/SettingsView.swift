import SwiftUI
import Observation

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(title: "Settings", subtitle: "Prototype controls")

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Reminders", isOn: $appState.remindersEnabled)
                        Toggle("Haptics", isOn: $appState.hapticsEnabled)
                        Toggle("Calm Mode", isOn: $appState.calmModeEnabled)
                    }
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textPrimary)
                    .tint(ODColor.primary)
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text("Current access")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)
                        Text(appState.accessSummary)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    ODInfoBanner(
                        title: "Runtime mode",
                        message: runtimeModeMessage,
                        icon: "internaldrive.fill",
                        tone: .success
                    )
                }
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .oneDoneScreen()
    }

    private var runtimeModeMessage: String {
        switch appState.services.runtimeMode {
        case .mock:
            return "Running in local mock mode. No Supabase, StoreKit, backend, or OpenAI calls are used."
        case .remoteAccessState:
            return "Using backend get-access-state and analyze-task when remote mode is enabled. Clarification answers, replies, reminders, and subscription actions remain local mock behavior."
        case .remotePlaceholder:
            return "Remote placeholder mode is scaffold-only and not intended for runtime."
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(appState: AppState())
    }
}
