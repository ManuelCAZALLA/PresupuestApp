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
            try items.save(item)
        case .update(let item):
            try items.save(item)
        case .delete(let id):
            try items.delete(id: id)
        }
    }
}
