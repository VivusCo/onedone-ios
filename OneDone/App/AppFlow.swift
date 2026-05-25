import SwiftUI
import Observation

struct AppFlow: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            ODColor.background.ignoresSafeArea()

            switch appState.phase {
            case .auth:
                AuthView(appState: appState)
            case .welcome:
                WelcomeView {
                    appState.beginOnboarding()
                }
            case .onboarding:
                OnboardingView(
                    page: appState.currentOnboardingPage,
                    progressText: appState.onboardingProgressText,
                    currentStep: appState.onboardingPageIndex,
                    totalSteps: appState.onboardingPages.count,
                    canGoBack: appState.onboardingPageIndex > 0,
                    isSubmitting: appState.isCompletingOnboarding,
                    submitErrorMessage: appState.onboardingCompletionErrorMessage,
                    onBack: { appState.previousOnboardingPage() },
                    onNext: {
                        Task {
                            await appState.nextOnboardingPage()
                        }
                    }
                )
            case .starterIntro:
                StarterAccessIntroView(showMockNotice: appState.services.runtimeMode == .mock) {
                    appState.enterMainApp()
                }
            case .access:
                AccessView(appState: appState)
            case .accessStateLoading:
                AccessStateLoadingView()
            case .accessStateError:
                AccessStateErrorView(
                    message: appState.accessStateLoadErrorMessage ??
                        "We could not load your access state right now."
                ) {
                    Task {
                        await appState.retryAccessStateLoad()
                    }
                } onUseMockMode: {
                    appState.continueWithMockSafeModeForDevelopment()
                }
            case .main:
                MainTabShell(appState: appState)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
        .task {
            await appState.bootstrapAppIfNeeded()
        }
    }
}

private struct MainTabShell: View {
    @Bindable var appState: AppState
    @State private var showTaskComposer: Bool = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HomeView(appState: appState)
            }
            .tabItem {
                Label(AppTab.home.rawValue, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            NavigationStack {
                TemplatesView(appState: appState)
            }
            .tabItem {
                Label(AppTab.templates.rawValue, systemImage: AppTab.templates.systemImage)
            }
            .tag(AppTab.templates)

            NavigationStack {
                MyTasksView(appState: appState)
            }
            .tabItem {
                Label(AppTab.tasks.rawValue, systemImage: AppTab.tasks.systemImage)
            }
            .tag(AppTab.tasks)

            NavigationStack {
                SettingsView(appState: appState)
            }
            .tabItem {
                Label(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage)
            }
            .tag(AppTab.settings)
        }
        .tint(ODColor.primary)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .overlay(alignment: .bottom) {
            ElevatedTaskTabButton(
                title: "Task",
                accessibilityLabel: "Create task"
            ) {
                showTaskComposer = true
            }
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showTaskComposer) {
            NavigationStack {
                NewTaskView(appState: appState, prefilledPrompt: nil)
            }
        }
    }
}

private struct AccessStateLoadingView: View {
    var body: some View {
        VStack(spacing: OneDoneStyle.contentSpacing) {
            ProgressView()
                .tint(ODColor.primary)

            Text("Loading access status...")
                .font(OneDoneStyle.bodyFont)
                .foregroundStyle(ODColor.textSecondary)
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }
}

private struct AccessStateErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onUseMockMode: () -> Void

    @State private var didShowFallbackMessage = false

    var body: some View {
        VStack(spacing: OneDoneStyle.sectionSpacing) {
            ODSectionHeader(
                title: "Could not load access",
                subtitle: "Connection or configuration issue"
            )

            ODCard {
                Text(message)
                    .font(OneDoneStyle.bodyFont)
                    .foregroundStyle(ODColor.textSecondary)
            }

            ODPrimaryButton(title: "Retry", icon: "arrow.clockwise") {
                onRetry()
            }

#if DEBUG
            ODSecondaryButton(title: "Use mock-safe mode (dev only)", icon: "wrench.and.screwdriver") {
                onUseMockMode()
                didShowFallbackMessage = true
            }

            if didShowFallbackMessage {
                ODInfoBanner(
                    title: "Development-only fallback",
                    message: "This uses local mock mode for testing and is not a production access bypass.",
                    icon: "exclamationmark.triangle.fill",
                    tone: .warning
                )
            }
#endif

            Spacer()
        }
        .padding(OneDoneStyle.screenPadding)
        .oneDoneScreen()
    }
}
