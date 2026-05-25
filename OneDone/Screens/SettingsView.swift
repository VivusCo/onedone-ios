import SwiftUI
import Observation

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var isLoggingOut: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(title: "Settings", subtitle: "Account, preferences, and privacy")

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Account")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        HStack(alignment: .top, spacing: OneDoneStyle.tightSpacing) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(ODColor.primary)
                                .padding(.top, 1)
                            Text(appState.authenticatedUserEmail ?? "Not signed in")
                                .font(OneDoneStyle.bodyFont)
                                .foregroundStyle(ODColor.textSecondary)
                                .textSelection(.enabled)
                        }

                        if appState.services.runtimeMode == .remoteAccessState {
                            HStack {
                                Spacer(minLength: 0)
                                ODSecondaryButton(
                                    title: isLoggingOut ? "Logging out..." : "Log out",
                                    icon: "rectangle.portrait.and.arrow.right",
                                    isDisabled: isLoggingOut,
                                    fullWidth: false
                                ) {
                                    Task {
                                        isLoggingOut = true
                                        await appState.logOut()
                                        isLoggingOut = false
                                    }
                                }
                                .frame(maxWidth: 280)
                                Spacer(minLength: 0)
                            }
                            .padding(.top, OneDoneStyle.space4)
                        }
                    }
                }

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Preferences")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

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
                        Text("Access")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)
                        Text(appState.accessSummary)
                            .font(OneDoneStyle.bodyFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                if let accessStatusNote = appState.accessStatusNote {
                    ODInfoBanner(
                        title: "Access update",
                        message: accessStatusNote,
                        icon: "info.circle.fill",
                        tone: .neutral
                    )
                }

#if DEBUG
                if appState.services.runtimeMode == .mock {
                    ODInfoBanner(
                        title: "Development mode",
                        message: "Mock mode is active for local previews and development only.",
                        icon: "wrench.and.screwdriver.fill",
                        tone: .warning
                    )
                }
#endif
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
