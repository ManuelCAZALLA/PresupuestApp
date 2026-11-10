import Foundation

/// Añade a un presupuesto las líneas de una agrupación, copiando nombre, unidad,
/// precio e IVA de cada partida en ese momento (snapshot), igual que `AddLine`.
/// Las cantidades son las definidas en la agrupación. Origen `.kit`.
public final class AddKitToQuote {
    private let quotes: QuoteRepository
    private let items: ItemRepository
    private let kits: KitRepository

    public init(quotes: QuoteRepository, items: ItemRepository, kits: KitRepository) {
        self.quotes = quotes
        self.items = items
        self.kits = kits
    }

    @discardableResult
    public func execute(kitID: UUID, in quoteID: UUID) throws -> [QuoteLine] {
        guard var quote = try quotes.quote(id: quoteID) else {
            throw DomainError.quoteNotFound
        }
        guard let kit = try kits.kit(id: kitID) else {
            throw DomainError.kitNotFound
        }

        var added: [QuoteLine] = []
        for entry in kit.entries {
            guard let item = try items.item(id: entry.itemID) else {
                throw DomainError.itemNotFound
            }
            let line = QuoteLine(
                itemID: item.id,
                name: item.name,
                unit: item.unit,
                quantity: entry.quantity,
                unitPrice: item.unitPrice,
                vatRate: item.vatRate ?? quote.defaultVATRate,
                origin: .kit
            )
            quote.lines.append(line)
            added.append(line)
        }
        try quotes.save(quote)
        return added
    }
}
