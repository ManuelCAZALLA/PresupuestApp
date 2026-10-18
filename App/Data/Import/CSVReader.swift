import Foundation
import QuoteCore

/// Codificación detectada al leer un CSV.
enum CSVEncoding: String, Equatable, Sendable {
    case utf8 = "utf-8"
    case windows1252 = "windows-1252"
}

/// Resultado de leer un CSV: la tabla y el formato detectado.
struct CSVReadResult: Equatable, Sendable {
    let table: RawTable
    let encoding: CSVEncoding
    let separator: Character
    let decimalSeparator: Character
}

/// Lector de CSV. Prueba UTF-8 y, si falla, Windows-1252; detecta el separador
/// (`,` o `;`) por frecuencia en la primera línea y respeta las comillas.
/// Ver docs/DECISIONS.md, D-008.
enum CSVReader {
    static func read(data: Data, name: String? = nil) throws -> CSVReadResult {
        guard let decoded = decode(data) else {
            throw DomainError.importFailed("No se pudo leer el CSV")
        }
        return read(text: decoded.text, name: name, encoding: decoded.encoding)
    }

    static func read(
        text: String,
        name: String? = nil,
        encoding: CSVEncoding = .utf8
    ) -> CSVReadResult {
        let separator = detectSeparator(in: text)
        let rows = parse(text: text, separator: separator)
        let decimal = detectDecimalSeparator(in: rows)
        return CSVReadResult(
            table: RawTable(name: name, rows: rows),
            encoding: encoding,
            separator: separator,
            decimalSeparator: decimal
        )
    }

    // MARK: - Codificación

    static func decode(_ data: Data) -> (text: String, encoding: CSVEncoding)? {
        if let text = String(data: data, encoding: .utf8) {
            return (text, .utf8)
        }
        if let text = String(data: data, encoding: .windowsCP1252) {
            return (text, .windows1252)
        }
        return nil
    }

    // MARK: - Separador y decimal

    static func detectSeparator(in text: String) -> Character {
        guard let firstLine = text.split(whereSeparator: \.isNewline).first else {
            return ","
        }
        let commas = firstLine.filter { $0 == "," }.count
        let semicolons = firstLine.filter { $0 == ";" }.count
        return semicolons > commas ? ";" : ","
    }

    /// Heurística para el formato: si algún campo escribe decimales con coma
    /// (`100,00`), el decimal es la coma; si no, el punto.
    static func detectDecimalSeparator(in rows: [[String]]) -> Character {
        for row in rows {
            for field in row where field.range(of: #"\d,\d"#, options: .regularExpression) != nil {
                return ","
            }
        }
        return "."
    }

    // MARK: - Parseo

    static func parse(text: String, separator: Character) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        let characters = Array(text)
        var index = 0

        func endRow() {
            row.append(field)
            rows.append(row)
            row = []
            field = ""
        }

        while index < characters.count {
            let character = characters[index]
            if inQuotes {
                if character == "\"" {
                    if index + 1 < characters.count, characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else if character == "\"" {
                inQuotes = true
            } else if character == separator {
                row.append(field)
                field = ""
            } else if character == "\n" {
                endRow()
            } else if character == "\r" {
                if index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }
                endRow()
            } else {
                field.append(character)
            }
            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            endRow()
        }

        // Quitar filas vacías finales.
        while let last = rows.last, last.allSatisfy({ $0.isEmpty }) {
            rows.removeLast()
        }
        return rows
    }
}
