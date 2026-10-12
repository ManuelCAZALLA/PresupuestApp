import Foundation

/// Repositorio de partidas del catálogo.
public protocol ItemRepository {
    func all() throws -> [Item]
    func item(id: UUID) throws -> Item?
    func save(_ item: Item) throws
    func delete(id: UUID) throws
}
