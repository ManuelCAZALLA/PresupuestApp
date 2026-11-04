import Foundation

/// Interpretación de una petición de presupuesto desde texto libre.
/// Salida: líneas con candidatos y estado (auto / ambiguous / none).
/// Es una función pura (mismo input + mismo catálogo = mismo resultado).
public protocol RequestInterpreting {
    func interpret(text: String, catalog: [Item]) -> [ParsedLine]
}

public struct ParsedLine: Equatable, Sendable {
    public let originalText: String
    public let quantity: Decimal
    public let quantityWasAssumed: Bool
    public let spokenUnit: MeasureUnit?
    public let candidates: [(item: Item, score: Double)]
    public let status: Status
    public let warnings: [Warning]

    public enum Status: String, Sendable { case auto, ambiguous, none }
    public enum Warning: Sendable { case unitMismatch }

    public init(
        originalText: String,
        quantity: Decimal,
        quantityWasAssumed: Bool,
        spokenUnit: MeasureUnit? = nil,
        candidates: [(item: Item, score: Double)] = [],
        status: Status,
        warnings: [Warning] = []
    ) {
        self.originalText = originalText
        self.quantity = quantity
        self.quantityWasAssumed = quantityWasAssumed
        self.spokenUnit = spokenUnit
        self.candidates = candidates
        self.status = status
        self.warnings = warnings
    }
}

extension ParsedLine {
    public static func == (lhs: ParsedLine, rhs: ParsedLine) -> Bool {
        lhs.originalText == rhs.originalText &&
        lhs.quantity == rhs.quantity &&
        lhs.quantityWasAssumed == rhs.quantityWasAssumed &&
        lhs.spokenUnit == rhs.spokenUnit &&
        lhs.candidates.map { $0.item.id } == rhs.candidates.map { $0.item.id } &&
        lhs.candidates.map { $0.score } == rhs.candidates.map { $0.score } &&
        lhs.status == rhs.status &&
        lhs.warnings.count == rhs.warnings.count
    }
}
