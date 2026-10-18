import Foundation

/// Añade una línea a un presupuesto copiando nombre, unidad, precio e IVA de
/// la partida en ese momento. El IVA de la línea es el de la partida si la
/// tiene; si no, el por defecto del presupuesto (docs/DOMAIN.md, "IVA por partida").
public final class AddLine {
    private let quotes: QuoteRepository
    private let items: ItemRepository

    public init(quotes: QuoteRepository, items: ItemRepository) {
        self.quotes = quotes
        self.items = items
    }

    @discardableResult
    public func execute(itemID: UUID, quantity: Decimal, in quoteID: UUID) throws -> QuoteLine {
        guard var quote = try quotes.quote(id: quoteID) else {
            throw DomainError.lineNotFound
        }
        guard let item = try items.item(id: itemID) else {
            throw DomainError.lineNotFound
        }

        let line = QuoteLine(
            itemID: item.id,
            name: item.name,
            unit: item.unit,
            quantity: quantity,
            unitPrice: item.unitPrice,
            vatRate: item.vatRate ?? quote.defaultVATRate,
            origin: .manual
        )
        quote.lines.append(line)
        try quotes.save(quote)
        return line
    }
}
