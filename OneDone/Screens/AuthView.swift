import SwiftUI
import Observation

struct AuthView: View {
    @Bindable var appState: AppState

    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OneDoneStyle.sectionSpacing) {
                ODSectionHeader(
                    title: "Welcome to OneDone",
                    subtitle: "Sign up or log in to continue"
                )

                IllustrationCard(
                    title: "Life admin, less messy",
                    subtitle: "Turn everyday admin tasks into clear steps.",
                    variant: .optimistic,
                    minHeight: 132
                )

                ODCard(style: .strong) {
                    VStack(alignment: .leading, spacing: OneDoneStyle.contentSpacing) {
                        ODTextField(
                            label: "Email",
                            placeholder: "you@example.com",
                            text: $email
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)

                        VStack(alignment: .leading, spacing: OneDoneStyle.tightSpacing) {
                            Text("Password")
                                .font(OneDoneStyle.subheadlineFont.weight(.medium))
                                .foregroundStyle(ODColor.textPrimary)

                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .padding(.horizontal, OneDoneStyle.controlHorizontalPadding)
                                .padding(.vertical, OneDoneStyle.controlVerticalPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                        .fill(ODColor.surfaceField)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                                .fill(ODColor.glassFillSecondary.opacity(0.66))
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: OneDoneStyle.controlCornerRadius, style: .continuous)
                                        .stroke(ODColor.borderField.opacity(0.9), lineWidth: 0.9)
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

                        Text("Securing your session...")
                            .font(OneDoneStyle.helperFont)
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

                Text("A guided self-service assistant. No autonomous actions.")
                    .font(OneDoneStyle.captionFont)
                    .foregroundStyle(ODColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, OneDoneStyle.space8)

                Spacer(minLength: OneDoneStyle.space12)
            }
            .padding(OneDoneStyle.screenPadding)
        }
        .oneDoneScreen()
        .scrollDismissesKeyboard(.interactively)
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
