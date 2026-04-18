import SwiftUI

/// Entry point for the Food Journal iOS application.  The `@main` struct
/// creates an `AppState` instance and injects it into the environment for
/// all child views.  The `MainTabView` defines the high‑level navigation
/// structure.
@main
struct FoodJournalApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}