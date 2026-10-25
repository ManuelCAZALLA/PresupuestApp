import Foundation

/// Guarda los datos editables de un presupuesto: cliente, validez, descuento,
/// notas y líneas. Número, fecha y estado NO cambian aquí: el estado solo se
/// mueve con `ChangeQuoteStatus` (docs/DOMAIN.md, regla 4).
public final class UpdateQuote {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute(_ quote: Quote) throws {
        guard var stored = try quotes.quote(id: quote.id) else {
            throw DomainError.quoteNotFound
        }
        stored.client = quote.client
        stored.validityDays = quote.validityDays
        stored.discount = quote.discount
        stored.notes = quote.notes
        stored.lines = quote.lines
        try quotes.save(stored)
    }
}
