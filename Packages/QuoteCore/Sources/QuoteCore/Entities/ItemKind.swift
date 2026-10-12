import Foundation

/// Tipo de partida: material, mano de obra, desplazamiento u otro (ver docs/DOMAIN.md).
public enum ItemKind: String, Codable, Sendable {
    case material
    case labor
    case travel
    case other
}
