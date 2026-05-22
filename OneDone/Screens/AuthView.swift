import SwiftUI
import Observation

struct AuthView: View {
    @Bindable var appState: AppState

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Welcome to OneDone",
                    subtitle: "Sign up or log in to continue"
                )

                ODCard {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        ODTextField(
                            label: "Email",
                            placeholder: "you@example.com",
                            text: $email
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)

                        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                            Text("Password")
                                .font(OneDoneStyle.subheadlineFont.weight(.medium))
                                .foregroundStyle(ODColor.textPrimary)

                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
                                .padding(.vertical, OneDoneStyle.controlVerticalPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                        .fill(ODColor.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                        .stroke(ODColor.border, lineWidth: 1)
                                )
                        }
                    }
                }

                ODPrimaryButton(
                    title: appState.isAuthActionInProgress ? "Signing up..." : "Sign up",
                    icon: "person.badge.plus",
                    isDisabled: !canSubmit || appState.isAuthActionInProgress
                ) {
                    Task {
                        await appState.signUp(email: normalizedEmail, password: password)
                    }
                }

                ODSecondaryButton(
                    title: appState.isAuthActionInProgress ? "Logging in..." : "Log in",
                    icon: "person.fill",
                    isDisabled: !canSubmit || appState.isAuthActionInProgress
                ) {
                    Task {
                        await appState.logIn(email: normalizedEmail, password: password)
                    }
                }

                if appState.isAuthActionInProgress {
                    HStack(spacing: OneDoneStyle.tightSpacing) {
                        ProgressView()
                            .tint(ODColor.primary)

                        Text("Contacting secure auth...")
                            .font(OneDoneStyle.subheadlineFont)
                            .foregroundStyle(ODColor.textSecondary)
                    }
                }

                if let info = appState.authInfoMessage {
                    ODInfoBanner(
                        title: "Auth update",
                        message: info,
                        icon: "info.circle.fill",
                        tone: .neutral
                    )
                }

                if let error = appState.authErrorMessage {
                    ODInfoBanner(
                        title: "Could not continue",
                        message: error,
                        icon: "exclamationmark.triangle.fill",
                        tone: .warning
                    )
                }

                Spacer(minLength: 12)
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .oneDoneScreen()
        .onAppear {
            if let knownEmail = appState.authenticatedUserEmail, email.isEmpty {
                email = knownEmail
            }
        }
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var canSubmit: Bool {
        !normalizedEmail.isEmpty && password.count >= 6
    }
}

#Preview {
    AuthView(appState: AppState())
}
