import Foundation

/// Errores del dominio (ver docs/ARCHITECTURE.md). Los tests definen el contrato.
public enum DomainError: Error, Equatable, Sendable {
    case emptyQuote
    case quotaExceeded
    case invalidTransition(from: QuoteStatus, to: QuoteStatus)
    case packNotFound(Trade)
    /// No se pudo leer un archivo importado (formato, codificación o contenido).
    case importFailed(String)
    /// La línea o el presupuesto pedido no existe.
    case lineNotFound
}
