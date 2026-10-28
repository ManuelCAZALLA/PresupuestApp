import Foundation
import QuoteCore
import UniformTypeIdentifiers

/// Tipos de archivo que la app acepta como tarifa. Se declara aquí (Data) para
/// que la vista no tenga que importar `UniformTypeIdentifiers`.
enum ImportFileTypes {
    static var allowed: [UTType] {
        var types: [UTType] = []
        if let xlsx = UTType(filenameExtension: "xlsx") { types.append(xlsx) }
        if let csv = UTType(filenameExtension: "csv") { types.append(csv) }
        return types.isEmpty ? [.data] : types
    }
}

/// Implementación local de `TariffImportSource`: une los lectores de archivo y
/// el intérprete de listas pegadas. Ver docs/DECISIONS.md, D-008.
struct LocalTariffSource: TariffImportSource {
    func tables(from url: URL) throws -> [RawTable] {
        switch url.pathExtension.lowercased() {
        case "xlsx":
            return try XLSXReader.read(url: url)
        default:
            let data = try readData(from: url)
            return [try CSVReader.read(data: data, name: url.lastPathComponent).table]
        }
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
