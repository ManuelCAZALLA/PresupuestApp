import Foundation

/// Oficio del usuario (ver docs/DOMAIN.md).
public enum Trade: String, Codable, Sendable {
    case plumber
    case mason
    case electrician
    case other
}
