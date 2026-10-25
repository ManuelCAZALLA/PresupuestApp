import Foundation

/// Repositorio del perfil de empresa (configuración única).
public protocol ProfileRepository {
    func load() throws -> BusinessProfile?
    func save(_ profile: BusinessProfile) throws
}
