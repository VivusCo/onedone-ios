import SwiftUI
import Observation

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ODSectionHeader(title: "Settings", subtitle: "Prototype controls")

                ODCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Reminders", isOn: $appState.remindersEnabled)
                        Toggle("Haptics", isOn: $appState.hapticsEnabled)
                        Toggle("Calm Mode", isOn: $appState.calmModeEnabled)
                    }
                    .tint(ODColor.primary)
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current access")
                            .font(.headline)
                        Text(appState.accessSummary)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data source")
                            .font(.headline)
                        Text("All content in this prototype is local mock data. No Supabase, StoreKit, backend, or OpenAI calls are used.")
                            .foregroundStyle(ODColor.textSecondary)
                    }
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
