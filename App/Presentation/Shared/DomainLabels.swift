import Foundation
import QuoteCore

/// Etiquetas visibles de los tipos del dominio.
/// Devuelve claves de Localizable.xcstrings.
enum DomainLabels {
    static func trade(_ trade: Trade) -> String {
        switch trade {
        case .plumber: return "trade.plumber"
        case .mason: return "trade.mason"
        case .electrician: return "trade.electrician"
        case .other: return "trade.other"
        }
    }

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
}
