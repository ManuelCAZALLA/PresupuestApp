import Foundation

/// Interpreta la unidad de medida de una fila. Ver docs/DECISIONS.md, D-008.
public enum UnitParser {
    public enum Outcome: Equatable, Sendable {
        case known(MeasureUnit)
        /// Unidad presente pero no reconocida: se usa `ud` y se avisa.
        case unknown(String)
        /// No había unidad: se usa `ud` sin aviso.
        case absent
    }

    /// Sinónimos reconocidos (clave normalizada sin acentos ni puntos).
    private static let aliases: [String: MeasureUnit] = [
        "ud": .unit, "u": .unit, "uds": .unit, "unidad": .unit, "unidades": .unit,
        "m": .meter, "ml": .meter, "metro": .meter, "metros": .meter,
        "m2": .squareMeter, "m²": .squareMeter,
        "m3": .cubicMeter, "m³": .cubicMeter,
        "h": .hour, "hora": .hour, "horas": .hour,
        "global": .lumpSum, "pa": .lumpSum, "lote": .lumpSum
    ]

    public static func parse(_ raw: String?) -> Outcome {
        guard let raw else { return .absent }
        let cleaned = normalize(raw)
        guard !cleaned.isEmpty else { return .absent }
        if let unit = aliases[cleaned] {
            return .known(unit)
        }
        return .unknown(raw)
    }

    static func normalize(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/."))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "es_ES")
            )
            .lowercased()
    }
}
