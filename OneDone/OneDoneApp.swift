import SwiftUI

@main
struct OneDoneApp: App {
    @State private var appState = OneDoneApp.makeInitialAppState()

    private static func makeInitialAppState() -> AppState {
        let environment = APIEnvironment.current

        if environment.useRemoteAccessState {
            return AppState(
                services: .remoteAccessState(
                    environment: environment,
                    tokenProvider: EnvironmentAuthTokenProvider()
                )
            )
        }

        return AppState(services: .mock)
    }

    var body: some Scene {
        WindowGroup {
            AppFlow(appState: appState)
                .preferredColorScheme(.light)
        }
    }
}
