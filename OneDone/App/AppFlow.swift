import SwiftUI
import Observation

struct AppFlow: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            ODWarmRadialBackground()

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
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: OneDoneStyle.radius24 + 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.radius24 + 10, style: .continuous)
                            .fill(ODColor.glassFillPrimary.opacity(0.78))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: OneDoneStyle.radius24 + 10, style: .continuous)
                            .stroke(ODColor.glassBorder.opacity(0.94), lineWidth: 0.95)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 22, x: 0, y: 12)
                    .frame(height: 78)

                HStack(spacing: 0) {
                    tabItem(for: .home)
                    tabItem(for: .templates)

                    Spacer(minLength: 84)

                    tabItem(for: .tasks)
                    tabItem(for: .settings)
                }
                .padding(.horizontal, 14)
                .padding(.top, 11)

                ElevatedTaskTabButton(
                    title: "Task",
                    accessibilityLabel: "Create task"
                ) {
                    showTaskComposer = true
                }
                .offset(y: -31)
            }
            .padding(.horizontal, OneDoneStyle.space20)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .sheet(isPresented: $showTaskComposer) {
            NavigationStack {
                NewTaskView(appState: appState, prefilledPrompt: nil)
            }
        }
    }

    private func tabItem(for tab: AppTab) -> some View {
        Button {
            appState.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(tabLabel(for: tab))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(appState.selectedTab == tab ? ODColor.accentPrimaryDeepGreen : ODColor.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
    }

    private func tabLabel(for tab: AppTab) -> String {
        switch tab {
        case .home:
            return "Home"
        case .templates:
            return "Templates"
        case .tasks:
            return "Tasks"
        case .settings:
            return "Settings"
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
