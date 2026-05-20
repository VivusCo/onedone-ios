import SwiftUI

@main
struct OneDoneApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppFlow(appState: appState)
                .preferredColorScheme(.light)
        }
    }
}
