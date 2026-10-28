import Foundation
import QuoteCore

/// Etiquetas visibles de los tipos del dominio.
/// Devuelve claves de Localizable.xcstrings.
enum DomainLabels {
    static func measureUnit(_ unit: MeasureUnit) -> String {
        switch unit {
        case .unit: return "measure.unit"
        case .meter: return "measure.meter"
        case .squareMeter: return "measure.squareMeter"
        case .cubicMeter: return "measure.cubicMeter"
        case .hour: return "measure.hour"
        case .lumpSum: return "measure.lumpSum"
        }
    }

    static func itemKind(_ kind: ItemKind) -> String {
        switch kind {
        case .material: return "kind.material"
        case .labor: return "kind.labor"
        case .travel: return "kind.travel"
        case .other: return "kind.other"
        }
    }

    /// Etiqueta de un aviso de importación (S8), por su tipo.
    static func importWarning(_ warning: ImportWarning) -> String {
        switch warning.type {
        case "sinPrecio": return "importTariff.warning.sinPrecio"
        case "precioInvalido": return "importTariff.warning.precioInvalido"
        case "unidadDesconocida": return "importTariff.warning.unidadDesconocida"
        case "duplicado": return "importTariff.warning.duplicado"
        case "precioAmbiguo": return "importTariff.warning.precioAmbiguo"
        case "precioSinMoneda": return "importTariff.warning.precioSinMoneda"
        default: return "importTariff.warning.generic"
        }
    }
}
