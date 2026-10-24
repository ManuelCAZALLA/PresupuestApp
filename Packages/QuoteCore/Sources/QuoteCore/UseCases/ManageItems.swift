import Foundation

/// Crea, edita y borra partidas del catálogo (ver docs/DOMAIN.md).
public final class ManageItems {
    public enum Operation: Equatable {
        case create(Item)
        case update(Item)
        case delete(UUID)
    }

    private let items: ItemRepository

    public init(items: ItemRepository) {
        self.items = items
    }

    public func execute(_ operation: Operation) throws {
        switch operation {
        case .create(let item):
            try upsert(item)
        case .update(let item):
            try items.save(item)
        case .delete(let id):
            try items.delete(id: id)
        }
    }

    /// Crea la partida o, si ya existe otra con el mismo nombre normalizado
    /// (`Item.nameKey`), actualiza esa en lugar de duplicarla. Es la regla que
    /// usa la importación para "añadir o reemplazar por nombre".
    private func upsert(_ item: Item) throws {
        guard let existing = try items.item(named: item.name) else {
            try items.save(item)
            return
        }
        try items.save(
            Item(
                id: existing.id,
                name: item.name,
                aliases: item.aliases,
                unit: item.unit,
                unitPrice: item.unitPrice,
                vatRate: item.vatRate,
                kind: item.kind,
                category: item.category
            )
        )
    }
}
