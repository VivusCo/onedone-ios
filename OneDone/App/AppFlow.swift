import SwiftUI
import Observation
import UIKit

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

    private enum ShellLayout {
        static let barHeight: CGFloat = 68
        static let insetHeight: CGFloat = 94
        static let barTopInset: CGFloat = 10
        static let barHorizontalPadding: CGFloat = 10
        static let contentBottomClearance: CGFloat = 98
        static let barBottomPadding: CGFloat = 4
    }

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
            Color.clear.frame(height: ShellLayout.contentBottomClearance)
        }
        .overlay(alignment: .bottom) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(ODColor.glassFillPrimary.opacity(0.70))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(ODColor.glassBorder.opacity(0.90), lineWidth: 0.9)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
                    .frame(height: ShellLayout.barHeight)
                    .padding(.top, ShellLayout.barTopInset)

                HStack(spacing: 0) {
                    tabItem(for: .home)
                    tabItem(for: .tasks)

                    Spacer(minLength: 0)
                        .frame(maxWidth: .infinity)

                    tabItem(for: .templates)
                    tabItem(for: .settings)
                }
                .padding(.horizontal, ShellLayout.barHorizontalPadding)
                .padding(.top, ShellLayout.barTopInset + 9)

                ElevatedTaskTabButton(
                    title: "Task",
                    accessibilityLabel: "Create task"
                ) {
                    showTaskComposer = true
                }
            }
            .frame(height: ShellLayout.insetHeight)
            .padding(.horizontal, OneDoneStyle.space20)
            .padding(.bottom, ShellLayout.barBottomPadding)
        }
        .sheet(isPresented: $showTaskComposer) {
            TaskComposerSheet(appState: appState)
        }
        .onAppear {
            // iOS 17+ can still render the native TabView bar in some layouts even when hidden via toolbar APIs.
            // Keep the system bar hidden while this custom glass tab shell is active.
            UITabBar.appearance().isHidden = true
        }
        .onDisappear {
            UITabBar.appearance().isHidden = false
        }
    }

    private func tabItem(for tab: AppTab) -> some View {
        Button {
            appState.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(tabLabel(for: tab))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(appState.selectedTab == tab ? ODColor.accentPrimaryDeepGreen : ODColor.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
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

private struct TaskComposerSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            NewTaskView(appState: appState, prefilledPrompt: nil)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ODColor.textSecondary)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(ODColor.glassFillSecondary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(ODColor.glassBorder.opacity(0.9), lineWidth: 0.9)
                                )
                        }
                        .accessibilityLabel("Close")
                    }
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
