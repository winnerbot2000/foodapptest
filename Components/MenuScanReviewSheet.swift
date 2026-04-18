import SwiftUI
import PhotosUI

struct MenuScanSubmission {
    let items: [ParsedMenuItem]
    let importedPhotoReferences: [PhotoReference]
    let recognizedText: String
}

struct MenuScanReviewSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let ownerID: UUID
    let restaurantID: UUID?
    let onApply: (MenuScanSubmission) -> Void

    @StateObject private var viewModel = MenuScanViewModel()
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                actionsSection
                suggestedItemsSection
                recognizedLinesSection
            }
            .navigationTitle("Menu Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Selected") {
                        Task {
                            await applySelection()
                        }
                    }
                    .disabled(viewModel.selectedParsedItems().isEmpty)
                }
            }
        }
        .alert(
            "Menu Scan",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        alertMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var photoSection: some View {
        Section(header: Text("Choose Menu Photo")) {
            PhotosPicker(
                selection: $viewModel.selectedPhotoItem,
                matching: .images
            ) {
                Label("Choose Menu Photo", systemImage: "menucard")
            }

            if viewModel.isLoadingPhoto {
                ProgressView("Loading photo...")
            }

            if let previewImage = viewModel.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Text("Select a menu image from your library, then run on-device OCR.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            }
        }
        .onChange(of: viewModel.selectedPhotoItem) { _ in
            Task {
                await viewModel.loadSelectedPhoto()
            }
        }
    }

    private var actionsSection: some View {
        Section(header: Text("Recognize Text")) {
            Button(viewModel.isRecognizing ? "Recognizing..." : "Recognize Text") {
                Task {
                    await viewModel.runRecognition()
                }
            }
            .disabled(viewModel.selectedPhotoItem == nil || viewModel.isLoadingPhoto || viewModel.isRecognizing)

            Toggle("Attach menu photo to this entry", isOn: $viewModel.attachMenuPhotoToEntry)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var suggestedItemsSection: some View {
        if !viewModel.editableItems.isEmpty {
            Section(header: Text("Select Items")) {
                Text("Review the suggestions below. Selected items will be added to the current entry flow.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                ForEach($viewModel.editableItems) { $item in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Toggle(isOn: $item.isSelected) {
                            Text("Include")
                                .font(AppTypography.caption)
                        }

                        TextField("Item Name", text: $item.name)

                        TextField("Price (Optional)", text: item.priceText)
                        .keyboardType(.decimalPad)

                        if let category = item.category.wrappedValue, !category.isEmpty {
                            Text("Category: \(category)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondary)
                        }

                        if let confidence = item.ocrConfidence.wrappedValue {
                            Text("OCR confidence: \(Int((confidence * 100).rounded()))%")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondary)
                        }

                        Button("Remove", role: .destructive) {
                            viewModel.removeDraft(id: item.id.wrappedValue)
                        }
                        .font(AppTypography.caption)
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
    }

    @ViewBuilder
    private var recognizedLinesSection: some View {
        if !viewModel.recognizedLines.isEmpty {
            Section(header: Text("Recognized Lines")) {
                Text("Tap a line to add it as a manual item suggestion if the parser missed it.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                ForEach(viewModel.recognizedLines) { line in
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(line.text)
                            .font(AppTypography.body)

                        HStack {
                            Text("Confidence: \(Int((line.confidence * 100).rounded()))%")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondary)

                            Spacer()

                            Button("Use as Item") {
                                viewModel.addDraft(from: line)
                            }
                            .font(AppTypography.caption)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
    }

    private func applySelection() async {
        let selectedItems = viewModel.selectedParsedItems()
        guard !selectedItems.isEmpty else {
            alertMessage = "Select at least one menu item to continue."
            return
        }

        var importedPhotoReferences: [PhotoReference] = []

        if viewModel.attachMenuPhotoToEntry, let selectedPhotoItem = viewModel.selectedPhotoItem {
            let photoImportResult = await appState.importPhotos(
                from: [selectedPhotoItem],
                owner: .entry,
                ownerID: ownerID
            )
            importedPhotoReferences = photoImportResult.references

            if !photoImportResult.messages.isEmpty {
                alertMessage = photoImportResult.messages.joined(separator: "\n")
                return
            }
        }

        appState.addMenuRecord(
            MenuRecord(
                restaurantId: restaurantID,
                scannedText: viewModel.recognizedText,
                parsedItems: selectedItems
            )
        )

        onApply(
            MenuScanSubmission(
                items: selectedItems,
                importedPhotoReferences: importedPhotoReferences,
                recognizedText: viewModel.recognizedText
            )
        )
        dismiss()
    }
}
