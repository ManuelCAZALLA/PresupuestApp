import Foundation

/// Opciones con las que se interpreta una tabla: si los precios traen IVA y
/// con qué tipo convertirlos. Ver docs/DECISIONS.md, D-008.
public struct ImportOptions: Equatable, Sendable {
    /// `true` si los precios del archivo incluyen IVA (se convierten a neto).
    public var vatIncluded: Bool
    /// Tipo de IVA en por ciento, p. ej. `21`.
    public var vatRate: Decimal

    public init(vatIncluded: Bool = false, vatRate: Decimal = Decimal(21)) {
        self.vatIncluded = vatIncluded
        self.vatRate = vatRate
    }
}

/// Convierte una `RawTable` en `ImportResult`: detecta la cabecera, sugiere
/// columnas y aplica el mapeo ya revisado. Ver docs/DECISIONS.md, D-008.
public enum ColumnMapper {
    private static let nameKeywords = [
        "concepto", "descripcion", "descrip", "nombre", "name", "articulo", "detalle"
    ]
    private static let unitKeywords = [
        "unidad", "ud", "unit", "medida", "uds", "unidades"
    ]
    private static let priceKeywords = [
        "precio", "precios", "pvp", "importe", "price", "coste", "tarifa"
    ]
    private static let categoryKeywords = [
        "categoria", "categorias", "category", "familia", "grupo", "seccion"
    ]

    // MARK: - Cabecera

    /// La primera fila con al menos 2 celdas de cabecera reconocibles.
    /// Devuelve el índice 0-based, o `nil` si no se detecta cabecera.
    public static func detectHeaderRow(in rows: [[String]]) -> Int? {
        for (index, row) in rows.enumerated() {
            let recognized = row.filter { isHeaderCell($0) }.count
            if recognized >= 2 {
                return index
            }
        }
        return nil
    }

    /// Sugerencia de mapeo a partir de la cabecera detectada.
    public static func suggestHeader(in rows: [[String]]) -> ColumnSuggestion {
        guard let headerRow = detectHeaderRow(in: rows) else {
            return ColumnSuggestion()
        }
        var suggestion = ColumnSuggestion(headerRow: headerRow)
        for (index, cell) in rows[headerRow].enumerated() {
            if suggestion.name == nil && matches(cell, nameKeywords) {
                suggestion.name = index
            } else if suggestion.unit == nil && matches(cell, unitKeywords) {
                suggestion.unit = index
            } else if suggestion.price == nil && matches(cell, priceKeywords) {
                suggestion.price = index
            } else if suggestion.category == nil && matches(cell, categoryKeywords) {
                suggestion.category = index
            }
        }
        return suggestion
    }

    /// `true` si algún texto hasta la cabecera dice que los precios llevan IVA
    /// ("IVA incluido", "IVA incl.", "PVP"). Se usa para prellenar el interruptor.
    public static func suggestedVATIncluded(in rows: [[String]]) -> Bool {
        guard !rows.isEmpty else { return false }
        let headerRow = detectHeaderRow(in: rows) ?? rows.count - 1
        for row in rows[0...max(0, min(headerRow, rows.count - 1))] {
            for cell in row {
                let folded = fold(cell)
                if folded.contains("iva incluido") || folded.contains("iva incl")
                    || folded.contains("pvp") || folded.contains("con iva") {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Mapeo

    /// Aplica un mapeo revisado a las filas que van **después** de la cabecera.
    public static func map(
        _ rows: [[String]],
        headerRow: Int?,
        mapping: ColumnMapping,
        options: ImportOptions
    ) -> ImportResult {
        let start = (headerRow ?? -1) + 1
        guard start < rows.count else { return ImportResult(rows: []) }

        var imported: [ImportedRow] = []
        var seenNames: Set<String> = []

        for row in rows[start...] {
            guard let rawName = value(row, mapping.name) else { continue }
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            let priceRaw = value(row, mapping.price)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let unitRaw = value(row, mapping.unit)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Fila de categoría, nota o vacía: texto sin precio ni unidad.
            if priceRaw.isEmpty && unitRaw.isEmpty { continue }

            var warnings: [ImportWarning] = []
            var net: Decimal = 0

            if priceRaw.isEmpty {
                warnings.append(.sinPrecio(name: name))
            } else {
                switch PriceParser.parse(priceRaw) {
                case .value(let gross, _):
                    net = netPrice(gross, options: options)
                case .ambiguous(let gross, let raw):
                    net = netPrice(gross, options: options)
                    warnings.append(.precioAmbiguo(name: name, raw: raw))
                case .invalid(let raw):
                    warnings.append(.precioInvalido(name: name, raw: raw))
                }
            }

            var unit: MeasureUnit = .unit
            if !unitRaw.isEmpty {
                switch UnitParser.parse(unitRaw) {
                case .known(let parsed): unit = parsed
                case .unknown(let raw): warnings.append(.unidadDesconocida(name: name, raw: raw))
                case .absent: break
                }
            }

            let category = value(row, mapping.category)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty

            if !seenNames.insert(Item.nameKey(name)).inserted {
                warnings.append(.duplicado(name: name))
            }

            imported.append(
                ImportedRow(
                    name: name,
                    unit: unit,
                    netPrice: net,
                    vatRate: options.vatRate,
                    kind: .other,
                    category: category,
                    warnings: warnings
                )
            )
        }

        return ImportResult(rows: imported)
    }

    // MARK: - Apoyo

    private static func netPrice(_ gross: Decimal, options: ImportOptions) -> Decimal {
        options.vatIncluded
            ? RoundingPolicy.netPrice(fromGross: gross, vatRate: options.vatRate)
            : gross
    }

    private static func value(_ row: [String], _ index: Int?) -> String? {
        guard let index, row.indices.contains(index) else { return nil }
        return row[index]
    }

    private static func isHeaderCell(_ cell: String) -> Bool {
        matches(cell, nameKeywords) || matches(cell, unitKeywords)
            || matches(cell, priceKeywords) || matches(cell, categoryKeywords)
    }

    private static func matches(_ cell: String, _ keywords: [String]) -> Bool {
        let words = fold(cell).split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        return words.contains { word in keywords.contains { word.hasPrefix($0) } }
    }

    private static func fold(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "es_ES")
        ).lowercased()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
