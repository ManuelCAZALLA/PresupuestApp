import CoreXLSX
import Foundation
import QuoteCore

/// Lector de `.xlsx` sobre CoreXLSX. Lee valores (nunca fórmulas) y conserva
/// los índices de fila para que la cabecera y las filas vacías coincidan con la
/// hoja. Devuelve una `RawTable` por hoja, con el nombre de la hoja.
/// Ver docs/DECISIONS.md, D-008 y D-009.
enum XLSXReader {
    private static let maxRows = 20_000
    private static let maxColumns = 200

    static func read(url: URL) throws -> [RawTable] {
        let data = try Data(contentsOf: url)
        return try read(data: data)
    }

    static func read(data: Data) throws -> [RawTable] {
        let file: XLSXFile
        do {
            file = try XLSXFile(data: data)
        } catch {
            throw DomainError.importFailed("No se pudo abrir el archivo .xlsx")
        }

        do {
            let sharedStrings = try file.parseSharedStrings()
            var tables: [RawTable] = []
            for workbook in try file.parseWorkbooks() {
                for (name, path) in try file.parseWorksheetPathsAndNames(workbook: workbook) {
                    let worksheet = try file.parseWorksheet(at: path)
                    tables.append(
                        RawTable(
                            name: name ?? "Hoja",
                            rows: rows(from: worksheet, sharedStrings: sharedStrings)
                        )
                    )
                }
            }
            guard !tables.isEmpty else {
                throw DomainError.importFailed("El archivo .xlsx no tiene hojas")
            }
            return tables
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.importFailed("No se pudo leer el contenido del .xlsx")
        }
    }

    // MARK: - Conversión a filas

    private static func rows(from worksheet: Worksheet, sharedStrings: SharedStrings?) -> [[String]] {
        let sheetRows = worksheet.data?.rows ?? []
        var rowCount = 0
        var columnCount = 0
        for row in sheetRows {
            rowCount = max(rowCount, Int(row.reference))
            for cell in row.cells {
                columnCount = max(columnCount, columnIndex(cell.reference.column) + 1)
            }
        }
        rowCount = min(rowCount, maxRows)
        columnCount = min(columnCount, maxColumns)
        guard rowCount > 0, columnCount > 0 else { return [] }

        var grid = Array(repeating: [String](repeating: "", count: columnCount), count: rowCount)
        for row in sheetRows {
            let rowIndex = Int(row.reference) - 1
            guard rowIndex >= 0, rowIndex < rowCount else { continue }
            for cell in row.cells {
                let column = columnIndex(cell.reference.column)
                guard column >= 0, column < columnCount else { continue }
                grid[rowIndex][column] = value(of: cell, sharedStrings: sharedStrings)
            }
        }
        return grid
    }

    private static func value(of cell: Cell, sharedStrings: SharedStrings?) -> String {
        if cell.type == .sharedString {
            if let sharedStrings, let string = cell.stringValue(sharedStrings) {
                return string
            }
            return cell.value ?? ""
        }
        if cell.type == .inlineStr {
            return cell.inlineString?.text ?? ""
        }
        return cell.value ?? ""
    }

    /// Índice 0-based de una columna: `A` → 0, `B` → 1, `AA` → 26.
    private static func columnIndex(_ reference: ColumnReference) -> Int {
        var index = 0
        for scalar in reference.value.unicodeScalars {
            index = index * 26 + Int(scalar.value) - 64
        }
        return index - 1
    }
}
