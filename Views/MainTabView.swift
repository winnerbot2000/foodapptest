import SwiftUI

/// Defines the root tab structure for the Food Journal app.  Each
/// tab hosts a section of the app inside its own `NavigationStack`.
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }

            RestaurantsView()
                .tabItem {
                    Label("Restaurants", systemImage: "fork.knife")
                }

            DishesView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
