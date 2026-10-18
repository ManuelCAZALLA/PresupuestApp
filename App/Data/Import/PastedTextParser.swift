import Foundation
import QuoteCore

/// Interpreta una lista pegada (p. ej. de WhatsApp): una línea por partida.
/// El precio es el último número de la línea; la unidad, el token `/ud`, `/m`,
/// `/h`… si existe; el resto es el nombre. Las líneas sin número (saludos,
/// notas) se ignoran. Ver docs/DECISIONS.md, D-008.
enum PastedTextParser {
    private static var numberRegex: Regex<Substring> { #/[0-9][0-9.,]*/# }
    private static let trailingSeparators = CharacterSet(charactersIn: "-–—:;,·•|.")

    static func parse(_ text: String, options: ImportOptions = ImportOptions()) -> ImportResult {
        var rows: [ImportedRow] = []
        var seenNames: Set<String> = []

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            guard let price = lastNumber(in: line) else { continue }

            let name = cleanName(String(line[line.startIndex..<price.range.lowerBound]))
            guard !name.isEmpty else { continue }

            let afterPrice = String(line[price.range.upperBound...])
            let hasSymbol = PriceParser.hasCurrencySymbol(line)

            var warnings: [ImportWarning] = []
            var net: Decimal = 0
            let outcome = PriceParser.parse(price.text)
            switch outcome {
            case .value(let gross, _):
                net = netPrice(gross, options: options)
            case .ambiguous(let gross, let raw):
                net = netPrice(gross, options: options)
                warnings.append(.precioAmbiguo(name: name, raw: raw))
            case .invalid(let raw):
                warnings.append(.precioInvalido(name: name, raw: raw))
            }
            if !hasSymbol, case .value = outcome {
                warnings.append(.precioSinMoneda(name: name))
            }

            var unit: MeasureUnit = .unit
            if let token = unitToken(in: afterPrice) {
                switch UnitParser.parse(token) {
                case .known(let parsed): unit = parsed
                case .unknown(let raw): warnings.append(.unidadDesconocida(name: name, raw: raw))
                case .absent: break
                }
            }

            if !seenNames.insert(Item.nameKey(name)).inserted {
                warnings.append(.duplicado(name: name))
            }

            rows.append(
                ImportedRow(
                    name: name,
                    unit: unit,
                    netPrice: net,
                    vatRate: options.vatRate,
                    warnings: warnings
                )
            )
        }

        return ImportResult(rows: rows)
    }

    // MARK: - Apoyo

    private static func netPrice(_ gross: Decimal, options: ImportOptions) -> Decimal {
        options.vatIncluded
            ? RoundingPolicy.netPrice(fromGross: gross, vatRate: options.vatRate)
            : gross
    }

    /// Último número de la línea, con su rango.
    private static func lastNumber(in line: String) -> (text: String, range: Range<String.Index>)? {
        guard let match = line.matches(of: numberRegex).last else { return nil }
        var text = String(line[match.range])
        while let last = text.last, last == "." || last == "," {
            text.removeLast()
        }
        guard !text.isEmpty, text.contains(where: { $0.isNumber }) else { return nil }
        return (text, match.range)
    }

    /// Token de unidad tras el precio: `/m`, `€/h`… `nil` si no hay.
    private static func unitToken(in text: String) -> String? {
        guard let slash = text.lastIndex(of: "/") else { return nil }
        let rest = text[text.index(after: slash)...]
        let token = String(rest.prefix { $0.isLetter || $0.isNumber })
        return token.isEmpty ? nil : token
    }

    private static func cleanName(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while let first = name.first,
              let scalar = first.unicodeScalars.first,
              trailingSeparators.contains(scalar) || first.isWhitespace {
            name.removeFirst()
        }
        while let last = name.last,
              let scalar = last.unicodeScalars.first,
              trailingSeparators.contains(scalar) || last.isWhitespace {
            name.removeLast()
        }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
