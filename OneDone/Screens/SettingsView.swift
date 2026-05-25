import SwiftUI
import Observation

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var isLoggingOut: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(title: "Settings", subtitle: "Account, access, preferences, and privacy")

                ODCard(style: .strong) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Account")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(ODColor.textPrimary)

                        settingsInfoRow(
                            icon: "person.crop.circle.fill",
                            title: "Signed in as",
                            detail: appState.authenticatedUserEmail ?? "Not signed in"
                        )
                        .textSelection(.enabled)

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
                                .frame(maxWidth: 260)
                                Spacer(minLength: 0)
                            }
                            .padding(.top, OneDoneStyle.space4)
                        }
                    }
                }

                ODCard(style: .default) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        Text("Preferences")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        settingsToggleRow(
                            icon: "bell.fill",
                            title: "Reminders",
                            isOn: $appState.remindersEnabled
                        )
                        settingsToggleRow(
                            icon: "waveform.path",
                            title: "Haptics",
                            isOn: $appState.hapticsEnabled
                        )
                        settingsToggleRow(
                            icon: "leaf.fill",
                            title: "Calm mode",
                            isOn: $appState.calmModeEnabled
                        )
                    }
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textPrimary)
                    .tint(ODColor.primary)
                }

                ODCard(style: .muted) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                        Text("Access")
                            .font(OneDoneStyle.cardTitleFont)
                            .foregroundStyle(ODColor.textPrimary)

                        HStack(spacing: OneDoneStyle.tightSpacing) {
                            ODStatusBadge(
                                title: appState.canCreateNewTasks ? "Creation available" : "Creation locked",
                                tone: appState.canCreateNewTasks ? .success : .warning
                            )
                            Spacer(minLength: OneDoneStyle.space8)
                        }

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

    private func settingsInfoRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: OneDoneStyle.tightSpacing) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: OneDoneStyle.space4) {
                Text(title)
                    .font(OneDoneStyle.captionFont.weight(.semibold))
                    .foregroundStyle(ODColor.textSecondary)
                    .textCase(.uppercase)
                Text(detail)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
        .padding(.vertical, OneDoneStyle.controlVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .fill(ODColor.glassFillSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: 0.9)
        )
    }

    private func settingsToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: OneDoneStyle.tightSpacing) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ODColor.accentPrimaryDeepGreen)
                .frame(width: 18, height: 18)

            Toggle(title, isOn: isOn)
                .toggleStyle(.switch)
        }
        .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
        .padding(.vertical, OneDoneStyle.controlVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .fill(ODColor.glassFillSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                .stroke(ODColor.glassBorder, lineWidth: 0.9)
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView(appState: AppState())
    }
}
