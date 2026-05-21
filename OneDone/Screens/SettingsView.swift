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
                        title: "Local data only",
                        message: "All content in this prototype is local mock data. No Supabase, StoreKit, backend, or OpenAI calls are used.",
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
}

#Preview {
    NavigationStack {
        SettingsView(appState: AppState())
    }
}
