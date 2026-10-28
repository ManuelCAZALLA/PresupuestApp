import Foundation

/// Carga un presupuesto por identificador.
public final class LoadQuote {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute(id: UUID) throws -> Quote {
        guard let quote = try quotes.quote(id: id) else {
            throw DomainError.quoteNotFound
        }
        return quote
    }
}
