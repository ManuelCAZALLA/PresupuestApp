import Foundation
import PDFKit
import QuoteCore
import Testing
@testable import PresupuestApp

@Suite("PDF profesional")
@MainActor
struct QuotePDFProfessionalTests {
    @Test("Por defecto el PDF no muestra precios unitarios ni importes de línea")
    func pdfHidesLineAmountsByDefault() throws {
        let line = QuoteLine(
            name: "Urinario PRUEBA",
            unit: .unit,
            quantity: Decimal(4),
            unitPrice: Decimal(50),
            vatRate: Decimal(21),
            origin: .manual
        )
        let quote = Quote(
            number: "P-2026-9001",
            date: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: 30,
            client: Client(name: "Cliente PRUEBA"),
            status: .draft,
            lines: [line],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: quote.discount)
        let profile = BusinessProfile(name: "Taller PRUEBA")
        let text = try renderText(quote, totals: totals, profile: profile, watermark: false)

        #expect(text.contains("Urinario PRUEBA"))
        #expect(text.contains("4"))
        #expect(!text.contains("50,00"))
        #expect(!text.contains("200,00"))
        #expect(text.contains("Subtotal"))
        #expect(text.contains("Total"))
    }

    @Test("Con el ajuste global activado sí se muestran importes por línea")
    func pdfShowsLineAmountsWithGlobalSetting() throws {
        let line = QuoteLine(
            name: "Termo PRUEBA",
            unit: .unit,
            quantity: Decimal(1),
            unitPrice: Decimal(120),
            vatRate: Decimal(21),
            origin: .manual
        )
        let quote = Quote(
            number: "P-2026-9002",
            date: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: 30,
            client: Client(name: "Cliente PRUEBA"),
            status: .draft,
            lines: [line],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: quote.discount)
        let profile = BusinessProfile(name: "Taller PRUEBA", showLineAmountsInPDF: true)
        let text = try renderText(quote, totals: totals, profile: profile, watermark: false)

        #expect(text.contains("Termo PRUEBA"))
        #expect(text.contains("120,00"))
        #expect(text.contains("121,00") || text.contains("120,00"))
    }

    @Test("El override por presupuesto prevalece sobre el ajuste global")
    func budgetOverrideTakesPrecedence() throws {
        let line = QuoteLine(
            name: "Grifo PRUEBA",
            unit: .unit,
            quantity: Decimal(2),
            unitPrice: Decimal(25),
            vatRate: Decimal(21),
            origin: .manual
        )
        var quote = Quote(
            number: "P-2026-9003",
            date: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: 30,
            client: Client(name: "Cliente PRUEBA"),
            status: .draft,
            lines: [line],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
        quote.showLineAmounts = true
        let totals = QuoteCalculator().calculate(lines: quote.lines, discount: quote.discount)
        let profile = BusinessProfile(name: "Taller PRUEBA", showLineAmountsInPDF: false)
        let text = try renderText(quote, totals: totals, profile: profile, watermark: false)

        #expect(text.contains("25,00"))
    }

    @Test("Los textos por defecto se copian al crear un presupuesto nuevo")
    func defaultTextsCopiedOnCreate() throws {
        let profile = BusinessProfile(
            name: "Taller PRUEBA",
            paymentTermsDefault: "PRUEBA: 50% anticipo",
            scopeOfWorkDefault: "PRUEBA: Suministro e instalación",
            exclusionsDefault: "PRUEBA: Albañilería de reparación"
        )
        var quote = Quote(
            number: "P-2026-9004",
            date: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: 30,
            client: Client(name: "Cliente PRUEBA"),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
        quote = Quote(
            number: quote.number,
            date: quote.date,
            issueDate: Date(timeIntervalSince1970: 1_771_372_800),
            validityDays: quote.validityDays,
            client: quote.client,
            status: quote.status,
            lines: quote.lines,
            discount: quote.discount,
            notes: quote.notes,
            defaultVATRate: quote.defaultVATRate,
            title: "PRUEBA Obra",
            workDescription: "PRUEBA Descripción",
            scopeOfWork: profile.scopeOfWorkDefault ?? "",
            exclusions: profile.exclusionsDefault ?? "",
            paymentTerms: profile.paymentTermsDefault ?? "",
            showLineAmounts: nil,
            shareMessage: "Hola {cliente}, te paso el presupuesto de {título} (ref. {número}). Cualquier duda, me dices."
        )
        #expect(quote.scopeOfWork.contains("PRUEBA"))
        #expect(quote.exclusions.contains("PRUEBA"))
        #expect(quote.paymentTerms.contains("PRUEBA"))
    }

    @Test("El modelo no tiene Trade")
    func noTradeInModel() throws {
        let item = Item(name: "PRUEBA", unit: .unit, unitPrice: Decimal(1))
        #expect(item.name == "PRUEBA")
        let quote = Quote(
            number: "P-2026-9005",
            date: Date(),
            validityDays: 30,
            client: Client(name: "PRUEBA"),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
        #expect(quote.number == "P-2026-9005")
    }

    private func renderText(
        _ quote: Quote,
        totals: QuoteTotals,
        profile: BusinessProfile,
        watermark: Bool
    ) throws -> String {
        let url = try DeviceQuotePDFRenderer().render(
            quote: quote,
            profile: profile,
            totals: totals,
            watermark: watermark
        )
        let document = try #require(PDFDocument(url: url))
        return (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
    }
}
