import Foundation

/// Repositorio de kits.
public protocol KitRepository {
    func all() throws -> [Kit]
    func kit(id: UUID) throws -> Kit?
    func save(_ kit: Kit) throws
    func delete(id: UUID) throws
}
