import SwiftUI
import PhotosUI
import UIKit

struct PhotoAttachmentSection: View {
    @EnvironmentObject private var appState: AppState

    let title: String
    let owner: PhotoOwnerKind
    let ownerID: UUID
    @Binding var photoReferences: [PhotoReference]
    var emptyStateText: String = "No photos attached yet."
    var onImportResult: ((PhotoImportResult) -> Void)? = nil
    var onRemovePhoto: ((PhotoReference) -> Void)? = nil

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var previewPhoto: PhotoReference?
    @State private var alertMessage: String?
    @State private var isImporting = false

    var body: some View {
        Section(header: Text(title)) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label(photoReferences.isEmpty ? "Add Photos" : "Add More Photos", systemImage: "photo.on.rectangle.angled")
            }

            if isImporting {
                ProgressView("Importing photos...")
            }

            if photoReferences.isEmpty {
                Text(emptyStateText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            } else {
                PhotoThumbnailGrid(
                    references: photoReferences,
                    removable: true,
                    onTap: { previewPhoto = $0 },
                    onRemove: removePhoto
                )
            }
        }
        .onChange(of: selectedItems) { newItems in
            guard !newItems.isEmpty else {
                return
            }

            Task {
                await importPhotos(from: newItems)
            }
        }
        .sheet(item: $previewPhoto) { reference in
            PhotoPreviewSheet(reference: reference)
                .environmentObject(appState)
        }
        .alert(
            "Photo Import",
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

    private func importPhotos(from items: [PhotosPickerItem]) async {
        isImporting = true
        let result = await appState.importPhotos(from: items, owner: owner, ownerID: ownerID)
        isImporting = false
        selectedItems = []

        let mergedReferences = mergePhotoReferences(photoReferences, with: result.references)
        photoReferences = mergedReferences
        onImportResult?(result)

        if !result.messages.isEmpty {
            alertMessage = result.messages.joined(separator: "\n")
        }
    }

    private func removePhoto(_ reference: PhotoReference) {
        photoReferences.removeAll { $0.id == reference.id }
        onRemovePhoto?(reference)
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

struct PhotoGallerySection: View {
    @EnvironmentObject private var appState: AppState

    let title: String
    let photoReferences: [PhotoReference]
    var emptyStateText: String = "No photos attached."

    @State private var previewPhoto: PhotoReference?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.headline)

            if photoReferences.isEmpty {
                Text(emptyStateText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            } else {
                PhotoThumbnailGrid(
                    references: photoReferences,
                    removable: false,
                    onTap: { previewPhoto = $0 },
                    onRemove: { _ in }
                )
            }
        }
        .sheet(item: $previewPhoto) { reference in
            PhotoPreviewSheet(reference: reference)
                .environmentObject(appState)
        }
    }
}

private struct PhotoThumbnailGrid: View {
    let references: [PhotoReference]
    let removable: Bool
    let onTap: (PhotoReference) -> Void
    let onRemove: (PhotoReference) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 88), spacing: AppSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(references) { reference in
                ZStack(alignment: .topTrailing) {
                    Button {
                        onTap(reference)
                    } label: {
                        PhotoThumbnailView(reference: reference)
                    }
                    .buttonStyle(.plain)

                    if removable {
                        Button {
                            onRemove(reference)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .black.opacity(0.65))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: -6)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

private struct PhotoThumbnailView: View {
    @EnvironmentObject private var appState: AppState

    let reference: PhotoReference

    @State private var image: UIImage?
    @State private var didAttemptLoad = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if didAttemptLoad {
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "photo")
                    Text("Unavailable")
                        .font(AppTypography.caption)
                }
                .foregroundColor(AppColors.secondary)
            } else {
                ProgressView()
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task(id: reference.relativePath) {
            didAttemptLoad = false
            if let imageData = await appState.loadPhotoData(reference) {
                image = UIImage(data: imageData)
            } else {
                image = nil
            }
            didAttemptLoad = true
        }
    }
}

private struct PhotoPreviewSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let reference: PhotoReference

    @State private var image: UIImage?
    @State private var didAttemptLoad = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.secondarySystemBackground))

                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else if didAttemptLoad {
                            VStack(spacing: AppSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                Text("This photo could not be loaded.")
                                    .font(AppTypography.body)
                            }
                            .foregroundColor(AppColors.secondary)
                            .padding()
                        } else {
                            ProgressView("Loading photo...")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 260)

                    metadataSection
                }
                .padding()
            }
            .navigationTitle(reference.originalFilename ?? "Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task(id: reference.relativePath) {
            didAttemptLoad = false
            if let imageData = await appState.loadPhotoData(reference) {
                image = UIImage(data: imageData)
            } else {
                image = nil
            }
            didAttemptLoad = true
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let captureDate = reference.captureDate {
                metadataLine(title: "Taken On", value: captureDate.formatted(date: .abbreviated, time: .shortened))
            }

            if let originalFilename = reference.originalFilename, !originalFilename.isEmpty {
                metadataLine(title: "Filename", value: originalFilename)
            }

            if let dimensionsText = reference.dimensionsText {
                metadataLine(title: "Dimensions", value: dimensionsText)
            }

            if let coordinateText = reference.coordinateText {
                metadataLine(title: "Coordinates", value: coordinateText)
            }

            metadataLine(title: "Stored Path", value: reference.relativePath)
        }
    }

    private func metadataLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondary)
            Text(value)
                .font(AppTypography.body)
        }
    }
}
