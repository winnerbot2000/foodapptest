import Foundation

/// Represents a single OCR line recognized from a menu image. The
/// lines are sorted into approximate reading order by the OCR service.
public struct RecognizedMenuLine: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var text: String
    public var confidence: Double
    public var sortIndex: Int

    public init(
        id: UUID = UUID(),
        text: String,
        confidence: Double,
        sortIndex: Int
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.sortIndex = sortIndex
    }
}

/// Bundles the OCR output from a menu scan. The `recognizedText`
/// string is kept for persistence/debugging, while `lines` support
/// user review and deterministic parsing.
public struct MenuOCRResult: Codable, Equatable {
    public var recognizedText: String
    public var lines: [RecognizedMenuLine]

    public init(recognizedText: String, lines: [RecognizedMenuLine]) {
        self.recognizedText = recognizedText
        self.lines = lines
    }
}
