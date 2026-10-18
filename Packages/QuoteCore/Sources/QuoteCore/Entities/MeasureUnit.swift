import Foundation

/// Unidad de medida de una partida (ver docs/DOMAIN.md).
public enum MeasureUnit: String, Codable, Sendable, CaseIterable {
    case unit        // ud
    case meter       // m
    case squareMeter // m2
    case cubicMeter  // m3
    case hour        // h
    case lumpSum     // global
}
