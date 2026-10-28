import Foundation

/// Quita una línea del presupuesto. El presupuesto puede quedarse vacío:
/// la regla de `emptyQuote` solo corta al marcarlo como enviado.
public final class RemoveLine {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute(quoteID: UUID, lineID: UUID) throws {
        guard var quote = try quotes.quote(id: quoteID) else {
            throw DomainError.quoteNotFound
        }
        guard let index = quote.lines.firstIndex(where: { $0.id == lineID }) else {
            throw DomainError.lineNotFound
        }
        quote.lines.remove(at: index)
        try quotes.save(quote)
    }
}
