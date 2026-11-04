import Foundation

public final class RequestInterpreter: RequestInterpreting {
    private let segmenter = Segmenter()
    private let quantityExtractor = QuantityExtractor()
    private let matcher = Matcher()
    
    public init() {}
    
    public func interpret(text: String, catalog: [Item]) -> [ParsedLine] {
        let segs = segmenter.segments(from: text)
        var results: [ParsedLine] = []
        for seg in segs {
            let extracted = quantityExtractor.extract(from: seg)
            let textToMatch = extracted.remainingText.isEmpty ? seg : extracted.remainingText
            let line = matcher.match(remainingText: textToMatch, quantity: extracted.quantity, quantityWasAssumed: extracted.quantityWasAssumed, spokenUnit: extracted.spokenUnit, catalog: catalog)
            results.append(line)
        }
        return results
    }
}
