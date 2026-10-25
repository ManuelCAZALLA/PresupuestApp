import Foundation

/// Cambia la cantidad de una línea ya añadida. El nombre, la unidad, el precio
/// y el IVA se quedan como estaban: son un snapshot del momento de añadirla.
public final class UpdateLineQuantity {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute(quoteID: UUID, lineID: UUID, quantity: Decimal) throws {
        guard var quote = try quotes.quote(id: quoteID) else {
            throw DomainError.quoteNotFound
        }
        guard let index = quote.lines.firstIndex(where: { $0.id == lineID }) else {
            throw DomainError.lineNotFound
        }
        quote.lines[index].quantity = quantity
        try quotes.save(quote)
    }
}
