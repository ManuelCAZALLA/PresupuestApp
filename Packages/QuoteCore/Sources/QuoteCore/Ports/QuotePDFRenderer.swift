import Foundation

/// Puerto para generar el PDF de un presupuesto en el dispositivo.
/// La implementación vive en `App/Data/PDF`; el dominio no conoce PDFKit.
public protocol QuotePDFRenderer: Sendable {
    func render(
        quote: Quote,
        profile: BusinessProfile,
        totals: QuoteTotals,
        watermark: Bool
    ) throws -> URL
}
