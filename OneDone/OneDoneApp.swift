import SwiftUI

@main
struct OneDoneApp: App {
    @State private var appState = OneDoneApp.makeInitialAppState()

    private static func makeInitialAppState() -> AppState {
        let environment = APIEnvironment.current

        if environment.forceMockRuntime {
            return AppState(services: .mock)
        }

        let sessionStore = AuthSessionStore()
        let tokenProvider = SessionAuthTokenProvider(sessionStore: sessionStore)

        return AppState(
            services: .remoteAccessState(
                environment: environment,
                tokenProvider: tokenProvider
            ),
            authService: SupabaseAuthService(environment: environment),
            authSessionStore: sessionStore
        )
    }

    var body: some Scene {
        WindowGroup {
            AppFlow(appState: appState)
                .preferredColorScheme(.light)
        }
    }
}
