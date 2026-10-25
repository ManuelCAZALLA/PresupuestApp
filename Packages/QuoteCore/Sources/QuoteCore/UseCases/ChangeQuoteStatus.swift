import Foundation

/// Cambia el estado de un presupuesto respetando la máquina de estados
/// (ver docs/DOMAIN.md): `draft → sent`; `sent → accepted | rejected | draft`.
/// `accepted` y `rejected` son terminales: cualquier otra transición lanza
/// `DomainError.invalidTransition(from:to:)`. Enviar un presupuesto sin
/// líneas lanza `DomainError.emptyQuote`.
public final class ChangeQuoteStatus {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute(_ quote: Quote, to status: QuoteStatus) throws -> Quote {
        switch (quote.status, status) {
        case (.draft, .sent), (.sent, .accepted), (.sent, .rejected), (.sent, .draft):
            break
        default:
            throw DomainError.invalidTransition(from: quote.status, to: status)
        }

        if status == .sent, quote.lines.isEmpty {
            throw DomainError.emptyQuote
        }

        var updated = quote
        updated.status = status
        try quotes.save(updated)
        return updated
    }
}
