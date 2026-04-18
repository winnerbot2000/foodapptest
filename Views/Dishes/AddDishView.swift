import SwiftUI

/// A form to create a new dish. Used from the dishes list and when
/// adding a new entry. Accepts an optional callback to return the
/// created dish to the presenting view.
struct AddDishView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let dishID: UUID?
    private let draftID: UUID
    private let originalPhotoReferences: [PhotoReference]
    private let onSave: ((Dish) -> Void)?

    @State private var name: String = ""
    @State private var category: DishCategory = .other
    @State private var subcategory: String = ""
    @State private var notes: String = ""
    @State private var photoReferences: [PhotoReference] = []
    @State private var importedPhotoReferences: [PhotoReference] = []
    @State private var didPersistChanges = false
    @State private var didRunDiscardCleanup = false

    init(dish: Dish? = nil, onSave: ((Dish) -> Void)? = nil) {
        self.dishID = dish?.id
        self.draftID = dish?.id ?? UUID()
        self.originalPhotoReferences = dish?.photoReferences ?? []
        self.onSave = onSave

        _name = State(initialValue: dish?.name ?? "")
        _category = State(initialValue: dish?.category ?? .other)
        _subcategory = State(initialValue: dish?.subcategory ?? "")
        _notes = State(initialValue: dish?.notes ?? "")
        _photoReferences = State(initialValue: dish?.photoReferences ?? [])
    }

    private var originalPhotoPaths: Set<String> {
        Set(originalPhotoReferences.map(\.relativePath))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("Dish Name", text: $name)
                }
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(DishCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    TextField("Subcategory", text: $subcategory)
                }
                Section(header: Text("Notes")) {
                    TextField("Optional notes", text: $notes)
                }
                PhotoAttachmentSection(
                    title: "Photos",
                    owner: .dish,
                    ownerID: draftID,
                    photoReferences: $photoReferences,
                    emptyStateText: "Attach reference photos for this dish."
                ) { result in
                    importedPhotoReferences = mergePhotoReferences(importedPhotoReferences, with: result.references)
                } onRemovePhoto: { reference in
                    handleRemovedPhoto(reference)
                }
            }
            .navigationTitle(dishID == nil ? "Add Dish" : "Edit Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(dishID == nil ? "Save" : "Update") {
                        didPersistChanges = true
                        saveDish()
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

    private func saveDish() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubcategory = subcategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let dishID, let existingDish = appState.dish(for: dishID) {
            var updatedDish = existingDish
            updatedDish.name = trimmedName
            updatedDish.category = category
            updatedDish.subcategory = trimmedSubcategory.isEmpty ? nil : trimmedSubcategory
            updatedDish.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            updatedDish.photoReferences = photoReferences
            appState.updateDish(updatedDish)
            onSave?(updatedDish)
        } else {
            let newDish = Dish(
                id: draftID,
                name: trimmedName,
                category: category,
                subcategory: trimmedSubcategory.isEmpty ? nil : trimmedSubcategory,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                photoReferences: photoReferences
            )
            appState.addDish(newDish)
            onSave?(newDish)
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
