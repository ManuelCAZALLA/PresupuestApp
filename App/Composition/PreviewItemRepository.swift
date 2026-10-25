import Foundation
import QuoteCore

/// Repositorio en memoria para previsualizaciones de Xcode y pruebas manuales
/// de la interfaz. Nunca se usa en la app real: `AppContainer` inyecta el
/// repositorio SwiftData. Ver docs/ARCHITECTURE.md.
final class PreviewItemRepository: ItemRepository {
    private var items: [UUID: Item] = [:]

    init(items: [Item] = []) {
        for item in items {
            self.items[item.id] = item
        }
    }

    func all() throws -> [Item] {
        items.values.sorted { $0.name < $1.name }
    }

    func item(id: UUID) throws -> Item? {
        items[id]
    }

    func item(named name: String) throws -> Item? {
        let key = Item.nameKey(name)
        return items.values.first { Item.nameKey($0.name) == key }
    }

    func save(_ item: Item) throws {
        items[item.id] = item
    }

    func delete(id: UUID) throws {
        items[id] = nil
    }
}
