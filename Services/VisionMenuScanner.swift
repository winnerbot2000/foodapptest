import Foundation
import Vision

enum MenuScannerError: LocalizedError {
    case invalidImageData
    case noTextFound
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The selected image could not be prepared for OCR."
        case .noTextFound:
            return "No readable menu text was found. Try another image or enter the item manually."
        case .recognitionFailed(let message):
            return message
        }
    }
}

/// Runs on-device OCR with Vision and applies deterministic menu
/// parsing heuristics. The parser stays conservative and relies on
/// user review for final confirmation.
struct VisionMenuScanner: MenuScannerProtocol {
    init() {}

    func recognizeMenu(from imageData: Data) async throws -> MenuOCRResult {
        guard !imageData.isEmpty else {
            throw MenuScannerError.invalidImageData
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: MenuScannerError.recognitionFailed(error.localizedDescription))
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let recognizedLines = recognizedMenuLines(from: observations)

                guard !recognizedLines.isEmpty else {
                    continuation.resume(throwing: MenuScannerError.noTextFound)
                    return
                }

                let recognizedText = recognizedLines.map(\.text).joined(separator: "\n")
                continuation.resume(returning: MenuOCRResult(recognizedText: recognizedText, lines: recognizedLines))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.015

            let preferredLanguages = Array(Locale.preferredLanguages.prefix(3))
            if !preferredLanguages.isEmpty {
                request.recognitionLanguages = preferredLanguages
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let handler = VNImageRequestHandler(data: imageData, options: [:])
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: MenuScannerError.recognitionFailed(error.localizedDescription))
                }
            }
        }
    }

    func parseMenuItems(from lines: [RecognizedMenuLine]) -> [ParsedMenuItem] {
        var parsedItems: [ParsedMenuItem] = []
        var currentCategory: String?

        for line in lines.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let normalizedText = collapseWhitespace(in: line.text)
            guard !normalizedText.isEmpty else {
                continue
            }

            if isNoiseLine(normalizedText) {
                continue
            }

            if isPriceOnlyLine(normalizedText) {
                if let lastIndex = parsedItems.indices.last, parsedItems[lastIndex].priceText == nil {
                    parsedItems[lastIndex].priceText = normalizedPriceText(from: normalizedText)
                }
                continue
            }

            let splitResult = splitTrailingPrice(from: normalizedText)
            let candidateName = sanitizeItemName(splitResult.namePart)

            guard containsLikelyMenuLetters(candidateName) else {
                continue
            }

            if isLikelyHeading(candidateName, hasPrice: splitResult.pricePart != nil) {
                currentCategory = candidateName
                continue
            }

            if candidateName.count < 2 {
                continue
            }

            let item = ParsedMenuItem(
                name: candidateName,
                priceText: splitResult.pricePart,
                category: currentCategory,
                sourceText: normalizedText,
                ocrConfidence: line.confidence
            )

            if !parsedItems.contains(where: {
                $0.name.caseInsensitiveCompare(item.name) == .orderedSame
                && ($0.priceText ?? "") == (item.priceText ?? "")
            }) {
                parsedItems.append(item)
            }
        }

        return parsedItems
    }

    func translate(_ text: String, to language: String) async throws -> String {
        // Translation remains an optional future hook. We keep the
        // protocol entry point so an Apple-native on-device translator
        // can be plugged in later without changing callers.
        return text
    }

    private func recognizedMenuLines(from observations: [VNRecognizedTextObservation]) -> [RecognizedMenuLine] {
        struct RawLine {
            let text: String
            let confidence: Double
            let minX: CGFloat
            let midY: CGFloat
        }

        let rawLines: [RawLine] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }

            let normalizedText = collapseWhitespace(in: candidate.string)
            guard !normalizedText.isEmpty else {
                return nil
            }

            return RawLine(
                text: normalizedText,
                confidence: Double(candidate.confidence),
                minX: observation.boundingBox.minX,
                midY: observation.boundingBox.midY
            )
        }

        let sortedLines = rawLines.sorted { lhs, rhs in
            let verticalDistance = abs(lhs.midY - rhs.midY)
            if verticalDistance > 0.025 {
                return lhs.midY > rhs.midY
            }
            return lhs.minX < rhs.minX
        }

        return sortedLines.enumerated().map { index, line in
            RecognizedMenuLine(
                text: line.text,
                confidence: line.confidence,
                sortIndex: index
            )
        }
    }

    private func collapseWhitespace(in text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isNoiseLine(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        if lowercased.contains("www.") || lowercased.contains("http") || lowercased.contains("@") {
            return true
        }

        let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "€$£¥.,-/&:+"))
        let filteredScalars = text.unicodeScalars.filter { allowed.contains($0) }
        if filteredScalars.isEmpty {
            return true
        }

        return text.trimmingCharacters(in: CharacterSet(charactersIn: "-_=*•·. ")).isEmpty
    }

    private func isPriceOnlyLine(_ text: String) -> Bool {
        let stripped = text.replacingOccurrences(of: " ", with: "")
        let pattern = #"^(?:[€$£¥])?\d{1,3}(?:[.,]\d{1,2})?(?:[€$£¥])?$"#
        return stripped.range(of: pattern, options: .regularExpression) != nil
    }

    private func splitTrailingPrice(from text: String) -> (namePart: String, pricePart: String?) {
        let pattern = #"(.*?)(?:\s+|^)((?:[€$£¥]\s?)?\d{1,3}(?:[.,]\d{1,2})?(?:\s?[€$£¥])?)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (text, nil)
        }
        let fullRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: fullRange),
              match.numberOfRanges >= 3,
              let nameRange = Range(match.range(at: 1), in: text),
              let priceRange = Range(match.range(at: 2), in: text) else {
            return (text, nil)
        }

        let priceCandidate = normalizedPriceText(from: String(text[priceRange]))
        let namePart = String(text[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !namePart.isEmpty, priceCandidate != nil else {
            return (text, nil)
        }

        return (namePart, priceCandidate)
    }

    private func sanitizeItemName(_ text: String) -> String {
        collapseWhitespace(in: text)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-•·:| "))
    }

    private func containsLikelyMenuLetters(_ text: String) -> Bool {
        text.unicodeScalars.contains(where: CharacterSet.letters.contains)
    }

    private func isLikelyHeading(_ text: String, hasPrice: Bool) -> Bool {
        guard !hasPrice else {
            return false
        }

        let words = text.split(separator: " ")
        if text.hasSuffix(":") && words.count <= 5 {
            return true
        }

        let letters = text.filter(\.isLetter)
        guard !letters.isEmpty else {
            return false
        }

        let uppercaseRatio = Double(letters.filter(\.isUppercase).count) / Double(letters.count)
        return words.count <= 4 && uppercaseRatio > 0.8
    }

    private func normalizedPriceText(from text: String) -> String? {
        let compact = text.replacingOccurrences(of: " ", with: "")
        let pattern = #"^(?:[€$£¥])?\d{1,3}(?:[.,]\d{1,2})?(?:[€$£¥])?$"#
        guard compact.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        return compact
    }
}
