import Foundation
import PhotosUI
import UIKit

struct EditableMenuItemDraft: Identifiable, Equatable {
    let id: UUID
    var isSelected: Bool
    var name: String
    var priceText: String
    var category: String?
    var sourceText: String?
    var ocrConfidence: Double?

    init(
        id: UUID = UUID(),
        isSelected: Bool = true,
        name: String,
        priceText: String = "",
        category: String? = nil,
        sourceText: String? = nil,
        ocrConfidence: Double? = nil
    ) {
        self.id = id
        self.isSelected = isSelected
        self.name = name
        self.priceText = priceText
        self.category = category
        self.sourceText = sourceText
        self.ocrConfidence = ocrConfidence
    }

    init(parsedItem: ParsedMenuItem) {
        self.init(
            name: parsedItem.name,
            priceText: parsedItem.priceText ?? "",
            category: parsedItem.category,
            sourceText: parsedItem.sourceText,
            ocrConfidence: parsedItem.ocrConfidence
        )
    }

    var asParsedMenuItem: ParsedMenuItem? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return nil
        }

        let trimmedPrice = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedMenuItem(
            name: trimmedName,
            priceText: trimmedPrice.isEmpty ? nil : trimmedPrice,
            category: category,
            sourceText: sourceText,
            ocrConfidence: ocrConfidence
        )
    }
}

@MainActor
final class MenuScanViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published private(set) var previewImage: UIImage?
    @Published private(set) var isLoadingPhoto = false
    @Published private(set) var isRecognizing = false
    @Published private(set) var recognizedResult: MenuOCRResult?
    @Published var editableItems: [EditableMenuItemDraft] = []
    @Published var attachMenuPhotoToEntry = false
    @Published var errorMessage: String?

    private let scanner: MenuScannerProtocol
    private(set) var selectedImageData: Data?

    init(scanner: MenuScannerProtocol = VisionMenuScanner()) {
        self.scanner = scanner
    }

    func loadSelectedPhoto() async {
        guard let selectedPhotoItem else {
            selectedImageData = nil
            previewImage = nil
            recognizedResult = nil
            editableItems = []
            return
        }

        isLoadingPhoto = true
        errorMessage = nil

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                throw MenuScannerError.invalidImageData
            }

            selectedImageData = data
            previewImage = UIImage(data: data)
            recognizedResult = nil
            editableItems = []
        } catch {
            selectedImageData = nil
            previewImage = nil
            recognizedResult = nil
            editableItems = []
            errorMessage = error.localizedDescription
        }

        isLoadingPhoto = false
    }

    func runRecognition() async {
        guard let selectedImageData else {
            errorMessage = "Choose a menu photo first."
            return
        }

        isRecognizing = true
        errorMessage = nil

        do {
            let result = try await scanner.recognizeMenu(from: selectedImageData)
            recognizedResult = result
            editableItems = scanner.parseMenuItems(from: result.lines).map(EditableMenuItemDraft.init(parsedItem:))

            if editableItems.isEmpty {
                errorMessage = "Text was recognized, but no strong menu item suggestions were found. You can still add lines manually below."
            }
        } catch {
            recognizedResult = nil
            editableItems = []
            errorMessage = error.localizedDescription
        }

        isRecognizing = false
    }

    func addDraft(from line: RecognizedMenuLine) {
        let trimmedText = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return
        }

        if editableItems.contains(where: { existing in
            existing.name.caseInsensitiveCompare(trimmedText) == .orderedSame
        }) {
            return
        }

        editableItems.append(
            EditableMenuItemDraft(
                name: trimmedText,
                sourceText: trimmedText,
                ocrConfidence: line.confidence
            )
        )
    }

    func removeDraft(id: UUID) {
        editableItems.removeAll { $0.id == id }
    }

    func selectedParsedItems() -> [ParsedMenuItem] {
        editableItems.compactMap { draft in
            guard draft.isSelected else {
                return nil
            }
            return draft.asParsedMenuItem
        }
    }

    var recognizedLines: [RecognizedMenuLine] {
        recognizedResult?.lines ?? []
    }

    var recognizedText: String {
        recognizedResult?.recognizedText ?? ""
    }
}
