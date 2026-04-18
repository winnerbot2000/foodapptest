import SwiftUI

/// A form to create a new restaurant. Used from the restaurants list
/// and when adding a new entry. Accepts an optional callback to
/// return the created restaurant to the presenting view.
struct AddRestaurantView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let restaurantID: UUID?
    private let draftID: UUID
    private let originalPhotoReferences: [PhotoReference]
    private let onSave: ((Restaurant) -> Void)?

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var cuisine: String = ""
    @State private var notes: String = ""
    @State private var photoReferences: [PhotoReference] = []
    @State private var importedPhotoReferences: [PhotoReference] = []
    @State private var didPersistChanges = false
    @State private var didRunDiscardCleanup = false

    init(restaurant: Restaurant? = nil, onSave: ((Restaurant) -> Void)? = nil) {
        self.restaurantID = restaurant?.id
        self.draftID = restaurant?.id ?? UUID()
        self.originalPhotoReferences = restaurant?.photoReferences ?? []
        self.onSave = onSave

        _name = State(initialValue: restaurant?.name ?? "")
        _location = State(initialValue: restaurant?.locationText ?? "")
        _cuisine = State(initialValue: restaurant?.cuisineTags.joined(separator: ", ") ?? "")
        _notes = State(initialValue: restaurant?.notes ?? "")
        _photoReferences = State(initialValue: restaurant?.photoReferences ?? [])
    }

    private var originalPhotoPaths: Set<String> {
        Set(originalPhotoReferences.map(\.relativePath))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("Restaurant Name", text: $name)
                }
                Section(header: Text("Location")) {
                    TextField("City or area", text: $location)
                }
                Section(header: Text("Cuisine Tags")) {
                    TextField("Comma separated", text: $cuisine)
                }
                Section(header: Text("Notes")) {
                    TextField("Optional notes", text: $notes)
                }
                PhotoAttachmentSection(
                    title: "Photos",
                    owner: .restaurant,
                    ownerID: draftID,
                    photoReferences: $photoReferences,
                    emptyStateText: "Attach storefront, menu, or dining room photos."
                ) { result in
                    importedPhotoReferences = mergePhotoReferences(importedPhotoReferences, with: result.references)
                } onRemovePhoto: { reference in
                    handleRemovedPhoto(reference)
                }
            }
            .navigationTitle(restaurantID == nil ? "Add Restaurant" : "Edit Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(restaurantID == nil ? "Save" : "Update") {
                        didPersistChanges = true
                        saveRestaurant()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onDisappear {
            cleanupDiscardedPhotosIfNeeded()
        }
    }

    private func saveRestaurant() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cuisineTags = cuisine
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let restaurantID, let existingRestaurant = appState.restaurant(for: restaurantID) {
            var updatedRestaurant = existingRestaurant
            updatedRestaurant.name = trimmedName
            updatedRestaurant.locationText = trimmedLocation
            updatedRestaurant.cuisineTags = cuisineTags
            updatedRestaurant.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            updatedRestaurant.photoReferences = photoReferences
            appState.updateRestaurant(updatedRestaurant)
            onSave?(updatedRestaurant)
        } else {
            let newRestaurant = Restaurant(
                id: draftID,
                name: trimmedName,
                locationText: trimmedLocation,
                cuisineTags: cuisineTags,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                photoReferences: photoReferences
            )
            appState.addRestaurant(newRestaurant)
            onSave?(newRestaurant)
        }
    }

    private func cleanupDiscardedPhotosIfNeeded() {
        guard !didPersistChanges, !didRunDiscardCleanup else {
            return
        }

        didRunDiscardCleanup = true
        let photosToDelete = importedPhotoReferences.filter { !originalPhotoPaths.contains($0.relativePath) }

        guard !photosToDelete.isEmpty else {
            return
        }

        Task {
            await appState.deleteDraftPhotos(photosToDelete)
        }
    }

    private func handleRemovedPhoto(_ reference: PhotoReference) {
        guard !originalPhotoPaths.contains(reference.relativePath) else {
            return
        }

        importedPhotoReferences.removeAll { $0.relativePath == reference.relativePath }
        Task {
            await appState.deleteDraftPhotos([reference])
        }
    }

    private func mergePhotoReferences(_ existing: [PhotoReference], with imported: [PhotoReference]) -> [PhotoReference] {
        var seenPaths = Set(existing.map(\.relativePath))
        var merged = existing

        for reference in imported where !seenPaths.contains(reference.relativePath) {
            seenPaths.insert(reference.relativePath)
            merged.append(reference)
        }

        return merged
    }
}
