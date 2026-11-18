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

    /// Texto localizado de un aviso de importación (S8), incluyendo el valor
    /// original cuando ayuda al usuario a corregirlo.
    static func importWarning(_ warning: ImportWarning) -> String {
        switch warning {
        case .unidadDesconocida(_, let raw):
            return formattedWarning("importTariff.warning.unidadDesconocida.detail", raw)
        case .precioInvalido(_, let raw):
            return formattedWarning("importTariff.warning.precioInvalido.detail", raw)
        case .precioAmbiguo(_, let raw):
            return formattedWarning("importTariff.warning.precioAmbiguo.detail", raw)
        case .vatInvalido(_, let raw):
            return formattedWarning("importTariff.warning.vatInvalido.detail", raw)
        case .sinPrecio:
            return String(localized: "importTariff.warning.sinPrecio")
        case .duplicado:
            return String(localized: "importTariff.warning.duplicado")
        case .precioSinMoneda:
            return String(localized: "importTariff.warning.precioSinMoneda")
        }
    }

    private static func formattedWarning(_ key: String, _ value: String) -> String {
        String.localizedStringWithFormat(NSLocalizedString(key, comment: ""), value)
    }
}
