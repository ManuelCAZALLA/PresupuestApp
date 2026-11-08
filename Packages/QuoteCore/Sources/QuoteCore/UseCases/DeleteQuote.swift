import Foundation

/// Elimina un presupuesto por su identificador.
public final class DeleteQuote {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute(id: Quote.ID) throws {
        try quotes.delete(id: id)
    }
}
