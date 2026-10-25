import Foundation

/// Estado de un presupuesto. `accepted` y `rejected` son terminales en el MVP.
public enum QuoteStatus: String, Codable, Equatable, Sendable {
    case draft
    case sent
    case accepted
    case rejected
}
