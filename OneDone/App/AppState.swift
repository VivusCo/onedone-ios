import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case templates = "Templates"
    case tasks = "My Tasks"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .templates:
            return "square.grid.2x2.fill"
        case .tasks:
            return "checklist"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let body: String
}

@Observable
final class AppState {
    enum Phase {
        case welcome
        case onboarding
        case starterIntro
        case access
        case main
    }

    var phase: Phase = .welcome
    var selectedTab: AppTab = .home

    var onboardingPageIndex: Int = 0
    var hasCompletedOnboarding: Bool = false
    var hasViewedStarterIntro: Bool = false
    let onboardingPages: [OnboardingPage] = [
        OnboardingPage(
            title: "OneDone keeps it simple",
            subtitle: "Guided self-service",
            body: "You bring a real task. OneDone helps you clarify it, draft a reply, and finish with calm momentum."
        ),
        OnboardingPage(
            title: "Text-first MVP",
            subtitle: "No noisy setup",
            body: "Start with plain text prompts and focused guidance. Attachments are intentionally disabled while we keep the core flow clean."
        ),
        OnboardingPage(
            title: "Progress in small steps",
            subtitle: "Starter Access first",
            body: "After onboarding, you get 3-day Starter Access. Then the App Store 14-day trial becomes available."
        )
    ]

    var starterAccessDaysTotal: Int = 3
    var starterAccessDaysUsed: Int = 0
    var starterAccessStarted: Bool = false
    var appStoreTrialActivated: Bool = false

    var remindersEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var calmModeEnabled: Bool = true

    var templates: [TaskTemplate] = MockRepository.templates
    var tasks: [MockTask] = MockRepository.seedTasks

    var currentOnboardingPage: OnboardingPage {
        onboardingPages[onboardingPageIndex]
    }

    var onboardingProgressText: String {
        "Step \(onboardingPageIndex + 1) of \(onboardingPages.count)"
    }

    var starterDaysRemaining: Int {
        max(0, starterAccessDaysTotal - starterAccessDaysUsed)
    }

    var isTrialEligible: Bool {
        starterAccessStarted && starterAccessDaysUsed >= starterAccessDaysTotal
    }

    var accessSummary: String {
        if !starterAccessStarted {
            return "Starter Access has not started yet."
        }

        if starterDaysRemaining > 0 {
            return "\(starterDaysRemaining) day(s) of Starter Access remaining."
        }

        if appStoreTrialActivated {
            return "App Store trial is active (mock)."
        }

        return "Starter Access completed. App Store trial can be activated."
    }

    func beginOnboarding() {
        phase = .onboarding
    }

    func nextOnboardingPage() {
        guard onboardingPageIndex < onboardingPages.count - 1 else {
            hasCompletedOnboarding = true
            phase = .starterIntro
            return
        }

        onboardingPageIndex += 1
    }

    func previousOnboardingPage() {
        guard onboardingPageIndex > 0 else { return }
        onboardingPageIndex -= 1
    }

    func goToAccessGate() {
        phase = .access
    }

    func completeStarterIntro() {
        hasViewedStarterIntro = true
    }

    func startStarterAccess() {
        starterAccessStarted = true
    }

    func simulateStarterDayProgress() {
        guard starterAccessStarted else { return }
        starterAccessDaysUsed = min(starterAccessDaysUsed + 1, starterAccessDaysTotal)
    }

    func activateAppStoreTrial() {
        guard isTrialEligible else { return }
        appStoreTrialActivated = true
    }

    func enterMainApp() {
        completeStarterIntro()
        startStarterAccess()
        phase = .main
    }

    func makeDraft(prompt: String, template: TaskTemplate?) -> TaskDraft {
        MockRepository.makeDraft(prompt: prompt, template: template)
    }

    func applyClarification(answer: String, to draft: TaskDraft) -> TaskDraft {
        MockRepository.applyClarification(answer: answer, to: draft)
    }

    func finalizeTask(from draft: TaskDraft, status: TaskStatus = .ready) -> MockTask {
        MockRepository.makeTask(from: draft, status: status)
    }

    func makeNeedsClarificationTask(from draft: TaskDraft) -> MockTask {
        MockRepository.makeTask(from: draft, status: .needsClarification)
    }

    func saveTask(_ task: MockTask) {
        guard !tasks.contains(where: { $0.id == task.id }) else { return }
        tasks.insert(task, at: 0)
    }
}
