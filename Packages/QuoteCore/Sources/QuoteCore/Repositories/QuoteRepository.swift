import Foundation

/// Repositorio de presupuestos.
public protocol QuoteRepository {
    func all() throws -> [Quote]
    func quote(id: UUID) throws -> Quote?
    func save(_ quote: Quote) throws
    func delete(id: UUID) throws
}
