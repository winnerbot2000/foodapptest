import SwiftUI

/// Displays application settings and data management options.  Users
/// can reset to sample data, clear all data, and read about the app.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                if let storageErrorMessage = appState.storageErrorMessage {
                    Section(header: Text("Storage Status")) {
                        Text(storageErrorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("Data")) {
                    Button("Reset to Sample Data") {
                        appState.resetSampleData()
                    }
                    Button("Clear All Data", role: .destructive) {
                        appState.clearAllData()
                    }
                }

                Section(header: Text("About")) {
                    Text("FoodJournal App v1.0")
                    Text("A personal food journaling app for tracking meals, dishes and restaurants.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
