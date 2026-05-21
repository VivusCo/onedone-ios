import SwiftUI
import Observation

struct AppFlow: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            ODColor.background.ignoresSafeArea()

            switch appState.phase {
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
                    onBack: { appState.previousOnboardingPage() },
                    onNext: { appState.nextOnboardingPage() }
                )
            case .starterIntro:
                StarterAccessIntroView {
                    appState.enterMainApp()
                }
            case .access:
                AccessView(appState: appState)
            case .main:
                MainTabShell(appState: appState)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
    }
}

private struct MainTabShell: View {
    @Bindable var appState: AppState

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
        .background(ODColor.background)
    }
}
