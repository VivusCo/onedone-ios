import SwiftUI
import Observation

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var isLoggingOut: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(title: "Settings", subtitle: "Prototype controls")

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text("Signed in account")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        Text(appState.authenticatedUserEmail ?? "Not signed in")
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)

                        if appState.services.runtimeMode == .remoteAccessState {
                            ODSecondaryButton(
                                title: isLoggingOut ? "Logging out..." : "Log out",
                                icon: "rectangle.portrait.and.arrow.right",
                                isDisabled: isLoggingOut
                            ) {
                                Task {
                                    isLoggingOut = true
                                    await appState.logOut()
                                    isLoggingOut = false
                                }
                            }
                        }
                    }
                }

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
                        tone: appState.services.runtimeMode == .remoteAccessState ? .success : .warning
                    )
                }

                if let accessStatusNote = appState.accessStatusNote {
                    ODInfoBanner(
                        title: "Access status",
                        message: accessStatusNote,
                        icon: "info.circle.fill",
                        tone: .neutral
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
            return "Running in local mock mode for previews/development fallback."
        case .remoteAccessState:
            return "Remote-first MVP runtime is active (Auth + access state + task APIs)."
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
