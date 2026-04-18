import Foundation

/// Defines an interface for scanning and parsing menus.  Implementations
/// may use OCR to recognise text, parse it into structured menu items
/// and optionally translate it.  Functions are asynchronous where
/// appropriate to support future network or heavy processing.
protocol MenuScannerProtocol {
    /// Recognises OCR lines from image data using an on-device pipeline
    /// and returns a result that preserves approximate reading order.
    func recognizeMenu(from imageData: Data) async throws -> MenuOCRResult

    /// Parses OCR lines into discrete menu item suggestions using
    /// deterministic rules only.
    func parseMenuItems(from lines: [RecognizedMenuLine]) -> [ParsedMenuItem]

    /// Translates a block of text into a target language.  The default
    /// implementation can simply return the original text until a real
    /// translation service is integrated.
    func translate(_ text: String, to language: String) async throws -> String
}
