import Foundation
import os
import QuoteCore
import UniformTypeIdentifiers

/// Tipos de archivo que la app acepta como tarifa. Se declara aquí (Data) para
/// que la vista no tenga que importar `UniformTypeIdentifiers`.
enum ImportFileTypes {
    /// `.xlsm` es el mismo contenedor OpenXML que `.xlsx`; `.xls` se acepta
    /// para poder explicar que el formato binario antiguo no se puede leer.
    private static let extensions = ["xlsx", "xlsm", "xls", "csv"]

    static var allowed: [UTType] {
        var types: [UTType] = []
        for fileExtension in extensions {
            guard let type = UTType(filenameExtension: fileExtension),
                  !types.contains(type) else { continue }
            types.append(type)
        }
        return types.isEmpty ? [.data] : types
    }
}

/// Implementación local de `TariffImportSource`: une los lectores de archivo y
/// el intérprete de listas pegadas. Ver docs/DECISIONS.md, D-008.
struct LocalTariffSource: TariffImportSource {
    private static let logger = Logger(
        subsystem: "com.manuelcazalla.PresupuestApp",
        category: "tariff-import"
    )

    func tables(from url: URL) throws -> [RawTable] {
        do {
            let data = try readData(from: url)
            return try Self.tables(from: data, fileName: url.lastPathComponent)
        } catch {
            Self.logger.error(
                "No se pudo leer la tarifa \(url.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    /// Detecta el formato por el contenido, no solo por la extensión: algunos
    /// programas guardan un libro OpenXML con extensión `.xls`, y otros
    /// exportan una tabla de texto con extensión `.xlsx`.
    static func tables(from data: Data, fileName: String) throws -> [RawTable] {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        if isZIP(data) {
            return try XLSXReader.read(data: data)
        }
        if isOLE(data) {
            throw DomainError.importFailed("legacy xls")
        }
        if let decoded = CSVReader.decode(data), isHTML(decoded.text) {
            throw DomainError.importFailed("html spreadsheet")
        }

        switch fileExtension {
        case "xlsx", "xlsm", "xls":
            guard let decoded = CSVReader.decode(data), !decoded.text.isEmpty else {
                throw DomainError.importFailed("invalid spreadsheet")
            }
            let result = CSVReader.read(
                text: decoded.text,
                name: fileName,
                encoding: decoded.encoding
            )
            guard result.table.rows.count >= 2,
                  result.table.rows.contains(where: { $0.count >= 2 }) else {
                throw DomainError.importFailed("invalid spreadsheet")
            }
            return [result.table]
        default:
            return [try CSVReader.read(data: data, name: fileName).table]
        }
    }

    private static func isZIP(_ data: Data) -> Bool {
        data.starts(with: [0x50, 0x4B, 0x03, 0x04])
            || data.starts(with: [0x50, 0x4B, 0x05, 0x06])
            || data.starts(with: [0x50, 0x4B, 0x07, 0x08])
    }

    /// Firma de un documento OLE (el `.xls` binario anterior a Office 2007).
    private static func isOLE(_ data: Data) -> Bool {
        data.starts(with: [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1])
    }

    private static func isHTML(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.contains("<html")
            || lowercased.contains("<table")
            || lowercased.contains("<tr")
    }

    func plainText(from url: URL) throws -> String {
        let data = try readData(from: url)
        guard let decoded = CSVReader.decode(data) else {
            throw DomainError.importFailed("No se pudo leer el archivo de texto")
        }
        return decoded.text
    }

    func parsePastedText(_ text: String, options: ImportOptions) -> ImportResult {
        PastedTextParser.parse(text, options: options)
    }

    private func readData(from url: URL) throws -> Data {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsScope { url.stopAccessingSecurityScopedResource() }
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw DomainError.importFailed("No se pudo abrir el archivo")
        }
    }
}
