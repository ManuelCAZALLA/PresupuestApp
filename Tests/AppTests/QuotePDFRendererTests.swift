import Foundation
import PDFKit
import QuoteCore
import Testing
import UIKit
@testable import PresupuestApp

@Suite("PDF del presupuesto")
struct QuotePDFRendererTests {
    @Test("El PDF incluye número, cliente, total y desglose de IVA")
    func pdfContainsRequiredText() throws {
        let lineA = QuoteLine(
            name: "Urinario PRUEBA",
            unit: .unit,
            quantity: Decimal(4),
            unitPrice: Decimal(50),
            vatRate: Decimal(21),
            origin: .manual
        )
        let lineB = QuoteLine(
            name: "Termo PRUEBA",
            unit: .unit,
            quantity: Decimal(1),
            unitPrice: Decimal(120),
            vatRate: Decimal(21),
            origin: .manual
        )
        let quote = Quote(
            id: UUID(),
            number: "P-2026-0001",
            date: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: 30,
            client: Client(name: "Cliente de prueba"),
            status: .draft,
            lines: [lineA, lineB],
            discount: .none,
            notes: "Notas de prueba",
            defaultVATRate: Decimal(21)
        )
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: quote.discount)
        let url = try DeviceQuotePDFRenderer().render(
            quote: quote,
            profile: BusinessProfile(name: "Taller PRUEBA", taxID: "B12345678"),
            totals: totals,
            watermark: true
        )
        let document = try #require(PDFDocument(url: url))
        let text = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
        #expect(text.contains("P-2026-0001"))
        #expect(text.contains("Cliente de prueba"))
        #expect(text.contains("387,20") || text.contains("387.20"))
        #expect(text.contains("21"))
        #expect(text.contains("Presupuesto"))
    }

    @Test("Tipos de IVA distintos y descuento: el desglose sale de QuoteCalculator")
    func mixedVATAndDiscount() throws {
        let quote = makeQuote(
            number: "P-2026-0002",
            lines: [
                makeLine(name: "Urinario PRUEBA", quantity: 4, unitPrice: 50, vatRate: 21),
                makeLine(name: "Mano de obra PRUEBA", quantity: 2, unitPrice: 100, vatRate: 10),
                makeLine(name: "Termo PRUEBA", quantity: 1, unitPrice: 120, vatRate: 21)
            ]
        )
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: .percent(Decimal(10)))

        // Subtotal 520, descuento 52 repartido (20 al 10 %, 32 al 21 %),
        // cuotas 18,00 y 60,48 → total 546,48.
        #expect(totals.total == Decimal(string: "546.48"))

        let text = try renderText(quote, totals: totals, watermark: false)
        #expect(text.contains("Descuento"))
        #expect(text.contains("IVA 10"))
        #expect(text.contains("IVA 21"))
        #expect(text.contains("18,00"))
        #expect(text.contains("60,48"))
        #expect(text.contains("546,48"))
    }

    @Test("Con 25 líneas cabe en una página y el total está")
    func twentyFiveLines() throws {
        let quote = makeQuote(number: "P-2026-0003", lines: lineItems(count: 25))
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: .none)

        let url = try render(quote, totals: totals, watermark: false)
        let document = try #require(PDFDocument(url: url))
        #expect(document.pageCount == 1)
        let text = text(of: document)
        #expect(text.contains("302,50"))
    }

    @Test("Con 80 líneas la tabla se parte y repite la cabecera")
    func eightyLinesPaginate() throws {
        let quote = makeQuote(number: "P-2026-0004", lines: lineItems(count: 80))
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: .none)

        let url = try render(quote, totals: totals, watermark: false)
        let document = try #require(PDFDocument(url: url))
        let pages = (0..<document.pageCount).map { document.page(at: $0)?.string ?? "" }

        #expect(document.pageCount >= 2)
        #expect(pages.filter { $0.contains("Concepto") }.count == document.pageCount)
        // El total no queda solo: subtotal y total van juntos en la última página.
        #expect(pages.last?.contains("Subtotal") == true)
        #expect(pages.last?.contains("968,00") == true)
    }

    @Test("El bloque de totales no queda solo en una página nueva")
    func totalsSharePageWithLines() throws {
        // La skill quote-pdf-export pide que el total nunca quede solo en una
        // página nueva. Con tres tipos de IVA el bloque de totales (128 pt) es
        // más alto que el hueco que reserva la tabla (120 pt).
        let rates: [Decimal] = [21, 10, 4]
        for count in 18...36 {
            let lines = (1...count).map { index in
                makeLine(
                    name: "Partida \(index) PRUEBA",
                    quantity: 1,
                    unitPrice: 10,
                    vatRate: rates[index % rates.count]
                )
            }
            let quote = makeQuote(number: "P-2026-1\(String(format: "%03d", count))", lines: lines)
            let totals = QuoteCalculator().calculate(lines: quote.lines, discount: .none)

            let url = try render(quote, totals: totals, watermark: false)
            let document = try #require(PDFDocument(url: url))
            let pages = (0..<document.pageCount).map { document.page(at: $0)?.string ?? "" }
            let totalsPage = try #require(pages.first { $0.contains("Total:") })

            #expect(totalsPage.contains("Concepto"), "con \(count) líneas el total quedó solo")
            #expect(totalsPage.contains("Subtotal"), "con \(count) líneas falta el subtotal")
        }
    }

    @Test("Sin marca de agua y con logo: el texto no lleva la marca")
    func watermarkAndLogo() throws {
        let quote = makeQuote(
            number: "P-2026-0005",
            lines: [makeLine(name: "Urinario PRUEBA", quantity: 1, unitPrice: 100, vatRate: 21)]
        )
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: .none)
        let profile = BusinessProfile(name: "Taller PRUEBA", logo: Self.onePixelPNG)

        let clean = try renderText(quote, totals: totals, watermark: false, profile: profile)
        #expect(!clean.contains("PresupuestApp"))
        #expect(clean.contains("Taller PRUEBA"))
        #expect(clean.contains("121,00"))

        let marked = try renderText(quote, totals: totals, watermark: true, profile: profile)
        #expect(marked.contains("PresupuestApp"))
    }

    // MARK: - Apoyo

    private func makeLine(
        name: String,
        quantity: Decimal,
        unitPrice: Decimal,
        vatRate: Decimal
    ) -> QuoteLine {
        QuoteLine(
            name: name,
            unit: .unit,
            quantity: quantity,
            unitPrice: unitPrice,
            vatRate: vatRate,
            origin: .manual
        )
    }

    private func lineItems(count: Int) -> [QuoteLine] {
        (1...count).map { index in
            makeLine(name: "Partida \(index) PRUEBA", quantity: 1, unitPrice: 10, vatRate: 21)
        }
    }

    private func makeQuote(number: String = "P-2026-0001", lines: [QuoteLine]) -> Quote {
        Quote(
            id: UUID(),
            number: number,
            date: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: 30,
            client: Client(name: "Cliente de prueba"),
            status: .draft,
            lines: lines,
            discount: .none,
            notes: "Notas de prueba",
            defaultVATRate: Decimal(21)
        )
    }

    private func render(
        _ quote: Quote,
        totals: QuoteTotals,
        watermark: Bool,
        profile: BusinessProfile = BusinessProfile(name: "Taller PRUEBA", taxID: "B12345678")
    ) throws -> URL {
        try DeviceQuotePDFRenderer().render(
            quote: quote,
            profile: profile,
            totals: totals,
            watermark: watermark
        )
    }

    private func renderText(
        _ quote: Quote,
        totals: QuoteTotals,
        watermark: Bool,
        profile: BusinessProfile = BusinessProfile(name: "Taller PRUEBA", taxID: "B12345678")
    ) throws -> String {
        text(of: try #require(PDFDocument(url: try render(quote, totals: totals, watermark: watermark, profile: profile))))
    }

    private func text(of document: PDFDocument) -> String {
        (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
    }

    /// PNG de 2 × 2 píxeles, para probar que el logo no rompe la maquetación.
    private static let onePixelPNG = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        .image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        .pngData()
}
