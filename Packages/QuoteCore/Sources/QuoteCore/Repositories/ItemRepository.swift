import Foundation

/// Repositorio de partidas del catálogo.
public protocol ItemRepository {
    func all() throws -> [Item]
    func item(id: UUID) throws -> Item?
    /// Busca una partida por su clave de nombre normalizada (`Item.nameKey`).
    /// Es la base del upsert para no duplicar partidas al importar.
    func item(named name: String) throws -> Item?
    func save(_ item: Item) throws
    func delete(id: UUID) throws
}
