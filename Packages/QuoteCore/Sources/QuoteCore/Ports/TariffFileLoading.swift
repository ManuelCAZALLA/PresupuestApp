import Foundation

/// Puerto de entrada de la tarifa del usuario: archivos y texto pegado.
/// Lo implementa Data (`App/Data/Import`); Presentation solo ve tablas y
/// resultados de dominio (`RawTable`, `ImportResult`), nunca formatos de archivo.
/// Ver docs/DECISIONS.md, D-008.
public protocol TariffImportSource {
    /// Tablas del archivo: una por hoja en `.xlsx`, una sola en `.csv`.
    func tables(from url: URL) throws -> [RawTable]
    /// Texto plano de un archivo (UTF-8 o Windows-1252), para interpretarlo
    /// como lista escrita.
    func plainText(from url: URL) throws -> String
    /// Interpreta una lista pegada (una partida por línea).
    func parsePastedText(_ text: String, options: ImportOptions) -> ImportResult
}

/// Puerto de la plantilla descargable: CSV con cabecera `Nombre;Unidad;Precio`,
/// sin precios (la app nunca inventa importes). Ver docs/PRODUCT.md (S8).
public protocol TariffTemplateProviding {
    /// Escribe la plantilla en una carpeta temporal y devuelve su URL para
    /// compartirla con la hoja del sistema.
    func temporaryTemplateURL() throws -> URL
}
