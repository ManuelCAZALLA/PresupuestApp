import Foundation

/// Repositorio de alias aprendidos por partida.
public protocol AliasRepository {
    func aliases(forItem itemID: UUID) throws -> [String]
    func add(alias: String, toItem itemID: UUID) throws
}
