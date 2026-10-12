import Foundation

/// Errores del dominio (ver docs/ARCHITECTURE.md). Los tests definen el contrato.
public enum DomainError: Error, Equatable, Sendable {
    case emptyQuote
    case quotaExceeded
    case invalidTransition(from: QuoteStatus, to: QuoteStatus)
}
