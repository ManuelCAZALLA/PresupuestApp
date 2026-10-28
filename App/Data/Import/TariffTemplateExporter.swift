import Foundation
import QuoteCore

/// Plantilla de importación que el usuario puede descargar y rellenar: CSV con
/// BOM UTF-8, separador `;` y coma decimal, columnas `Nombre;Unidad;Precio`.
/// Solo lleva la cabecera: la app nunca rellena precios. Ver docs/DECISIONS.md,
/// D-008 y docs/PRODUCT.md (S8).
struct FileTariffTemplateProvider: TariffTemplateProviding {
    static let fileName = "Plantilla_tarifa.csv"
    static let header = "Nombre;Unidad;Precio"

    static func csvString() -> String {
        // `\u{FEFF}` es el BOM: ayuda a Excel a abrir el archivo en UTF-8.
        "\u{FEFF}" + header + "\n"
    }

    static func data() -> Data {
        Data(csvString().utf8)
    }

    func temporaryTemplateURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TariffTemplate", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(Self.fileName)
        try Self.data().write(to: url, options: .atomic)
        return url
    }
}
