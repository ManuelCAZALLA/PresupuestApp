import Foundation

public struct ParsedLine: Equatable {
    public enum Status: String, Equatable {
        case auto
        case ambiguous
        case none
    }
    
    public enum Warning: String, Equatable {
        case unitMismatch
    }
    
    public let originalText: String
    public let quantity: Decimal
    public let quantityWasAssumed: Bool
    public let spokenUnit: MeasureUnit?
    public let candidates: [(item: Item, score: Double)]
    public let status: Status
    public let warnings: [Warning]
    
    public init(originalText: String, quantity: Decimal, quantityWasAssumed: Bool, spokenUnit: MeasureUnit?, candidates: [(item: Item, score: Double)], status: Status, warnings: [Warning]) {
        self.originalText = originalText
        self.quantity = quantity
        self.quantityWasAssumed = quantityWasAssumed
        self.spokenUnit = spokenUnit
        self.candidates = candidates
        self.status = status
        self.warnings = warnings
    }
    
    public static func == (lhs: ParsedLine, rhs: ParsedLine) -> Bool {
        lhs.originalText == rhs.originalText &&
        lhs.quantity == rhs.quantity &&
        lhs.quantityWasAssumed == rhs.quantityWasAssumed &&
        lhs.spokenUnit == rhs.spokenUnit &&
        lhs.candidates.count == rhs.candidates.count &&
        zip(lhs.candidates, rhs.candidates).allSatisfy { $0.item == $1.item && abs($0.score - $1.score) < 0.0001 } &&
        lhs.status == rhs.status &&
        lhs.warnings == rhs.warnings
    }
}
