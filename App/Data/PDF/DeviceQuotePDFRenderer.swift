import Foundation
import PDFKit
import QuoteCore
import UIKit

/// Genera el PDF A4 del presupuesto en el dispositivo (docs/PRODUCT.md, S6).
struct DeviceQuotePDFRenderer: QuotePDFRenderer {
    private static let pageRect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    private static let margin: CGFloat = 51 // 18 mm

    func render(
        quote: Quote,
        profile: BusinessProfile,
        totals: QuoteTotals,
        watermark: Bool
    ) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: Self.pageRect)
        let showLineAmounts = quote.showLineAmounts ?? profile.showLineAmountsInPDF
        let data = renderer.pdfData { context in
            var cursor = Self.margin
            context.beginPage()
            if watermark {
                drawWatermark(in: context)
            }
            cursor = drawHeader(profile: profile, at: cursor)
            cursor = drawTitle(quote: quote, at: cursor)
            cursor = drawClient(quote.client, at: cursor)
            cursor = drawQuoteDetails(quote: quote, at: cursor)
            cursor = drawLines(
                quote: quote,
                context: context,
                startY: cursor,
                reserveForTotals: Self.totalsBlockHeight(totals),
                watermark: watermark,
                showLineAmounts: showLineAmounts
            )
            cursor = drawTotals(totals, at: cursor, context: context, watermark: watermark)
            _ = drawTerms(profile: profile, quote: quote, at: cursor, context: context, watermark: watermark)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: quote))
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Nombre de archivo

    private func fileName(for quote: Quote) -> String {
        let client = quote.client.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = client.isEmpty ? "cliente" : client
        return "Presupuesto-\(quote.number)-\(suffix).pdf"
    }

    // MARK: - Bloques

    private func drawHeader(profile: BusinessProfile, at y: CGFloat) -> CGFloat {
        var y = y
        if let logo = profile.logo.flatMap({ UIImage(data: $0) }) {
            let size = CGSize(width: 64, height: 64)
            logo.draw(in: CGRect(x: Self.margin, y: y, width: size.width, height: size.height))
            y += size.height + 8
        }
        y = draw(profile.name.isEmpty ? "—" : profile.name, font: .boldSystemFont(ofSize: 14), at: y)
        if !profile.address.isEmpty { y = draw(profile.address, font: .systemFont(ofSize: 10), at: y) }
        if !profile.taxID.isEmpty { y = draw(profile.taxID, font: .systemFont(ofSize: 10), at: y) }
        if !profile.phone.isEmpty { y = draw(profile.phone, font: .systemFont(ofSize: 10), at: y) }
        if !profile.email.isEmpty { y = draw(profile.email, font: .systemFont(ofSize: 10), at: y) }
        if let iban = profile.iban, !iban.isEmpty { y = draw("IBAN: \(iban)", font: .systemFont(ofSize: 9), at: y) }
        return y + 10
    }

    private func drawTitle(quote: Quote, at y: CGFloat) -> CGFloat {
        var y = draw("Presupuesto", font: .boldSystemFont(ofSize: 18), at: y)
        y = draw("N.º \(quote.number)", font: .systemFont(ofSize: 11), at: y)
        if !quote.title.isEmpty {
            y = draw("Obra: \(quote.title)", font: .systemFont(ofSize: 11), at: y)
        }
        y = draw("Fecha: \(Self.dateFormatter.string(from: quote.issueDate))", font: .systemFont(ofSize: 10), at: y)
        if let until = Calendar.current.date(byAdding: .day, value: quote.validityDays, to: quote.issueDate) {
            y = draw("Válido hasta \(Self.dateFormatter.string(from: until))", font: .systemFont(ofSize: 10), at: y)
        }
        return y + 12
    }

    private func drawQuoteDetails(quote: Quote, at y: CGFloat) -> CGFloat {
        var y = y
        if !quote.workDescription.isEmpty {
            y = draw("Descripción de los trabajos", font: .boldSystemFont(ofSize: 11), at: y)
            y = draw(quote.workDescription, font: .systemFont(ofSize: 9), at: y)
            y += 6
        }
        if !quote.scopeOfWork.isEmpty {
            y = draw("Alcance", font: .boldSystemFont(ofSize: 11), at: y)
            y = draw(quote.scopeOfWork, font: .systemFont(ofSize: 9), at: y)
            y += 6
        }
        if !quote.exclusions.isEmpty {
            y = draw("Exclusiones", font: .boldSystemFont(ofSize: 11), at: y)
            y = draw(quote.exclusions, font: .systemFont(ofSize: 9), at: y)
            y += 6
        }
        return y
    }

    private func drawClient(_ client: Client, at y: CGFloat) -> CGFloat {
        var y = draw("Cliente", font: .boldSystemFont(ofSize: 11), at: y)
        y = draw(client.name.isEmpty ? "—" : client.name, font: .systemFont(ofSize: 10), at: y)
        if !client.phone.isEmpty { y = draw(client.phone, font: .systemFont(ofSize: 10), at: y) }
        if !client.address.isEmpty { y = draw(client.address, font: .systemFont(ofSize: 10), at: y) }
        if let work = client.workAddress, !work.isEmpty {
            y = draw("Obra: \(work)", font: .systemFont(ofSize: 10), at: y)
        }
        return y + 12
    }

    private func drawLines(
        quote: Quote,
        context: UIGraphicsPDFRendererContext,
        startY: CGFloat,
        reserveForTotals: CGFloat,
        watermark: Bool,
        showLineAmounts: Bool
    ) -> CGFloat {
        var columns: [(String, CGFloat)] = [
            ("Concepto", 280),
            ("Ud", 36),
            ("Cant.", 60)
        ]
        if showLineAmounts {
            columns.append(contentsOf: [("Precio", 70), ("Total", 70)])
        }
        var y = drawTableHeader(columns, at: startY)
        let calculator = QuoteCalculator()
        for line in quote.lines {
            let needed: CGFloat = 18
            if y + needed + reserveForTotals > Self.pageRect.height - Self.margin {
                context.beginPage()
                if watermark { drawWatermark(in: context) }
                y = Self.margin
                y = drawTableHeader(columns, at: y)
            }
            let total = calculator.lineTotal(line)
            var values = [
                line.name,
                unitLabel(line.unit),
                formatAmount(line.quantity)
            ]
            if showLineAmounts {
                values.append(contentsOf: [formatMoney(line.unitPrice), formatMoney(total)])
            }
            var x = Self.margin
            for (index, column) in columns.enumerated() {
                let align: NSTextAlignment = index == 0 ? .left : .right
                draw(values[index], font: .systemFont(ofSize: 9), in: CGRect(x: x, y: y, width: column.1, height: 16), alignment: align)
                x += column.1 + 8
            }
            y += 16
        }
        return y + 10
    }

    /// Alto del bloque de totales (subtotal, descuento, desglose de IVA y total).
    /// La tabla lo reserva al paginar para que el total nunca quede solo.
    private static func totalsBlockHeight(_ totals: QuoteTotals) -> CGFloat {
        80 + CGFloat(totals.vatBreakdown.count) * 16
    }

    private func drawTableHeader(_ columns: [(String, CGFloat)], at y: CGFloat) -> CGFloat {
        var x = Self.margin
        for column in columns {
            draw(column.0, font: .boldSystemFont(ofSize: 9), in: CGRect(x: x, y: y, width: column.1, height: 16), alignment: .left)
            x += column.1 + 8
        }
        return y + 18
    }

    private func drawTotals(
        _ totals: QuoteTotals,
        at y: CGFloat,
        context: UIGraphicsPDFRendererContext,
        watermark: Bool
    ) -> CGFloat {
        var y = y
        let blockHeight = Self.totalsBlockHeight(totals)
        if y + blockHeight > Self.pageRect.height - Self.margin {
            context.beginPage()
            if watermark { drawWatermark(in: context) }
            y = Self.margin
        }
        y = draw("Subtotal: \(formatMoney(totals.subtotal))", font: .systemFont(ofSize: 10), at: y)
        if totals.discount > 0 {
            y = draw("Descuento: −\(formatMoney(totals.discount))", font: .systemFont(ofSize: 10), at: y)
        }
        for group in totals.vatBreakdown {
            y = draw(
                "IVA \(formatAmount(group.rate)) %  base \(formatMoney(group.base))  cuota \(formatMoney(group.vat))",
                font: .systemFont(ofSize: 10),
                at: y
            )
        }
        y = draw("Total: \(formatMoney(totals.total))", font: .boldSystemFont(ofSize: 13), at: y + 4)
        return y + 14
    }

    private func drawTerms(
        profile: BusinessProfile,
        quote: Quote,
        at y: CGFloat,
        context: UIGraphicsPDFRendererContext,
        watermark: Bool
    ) -> CGFloat {
        var y = y
        if y > Self.pageRect.height - Self.margin - 120 {
            context.beginPage()
            if watermark { drawWatermark(in: context) }
            y = Self.margin
        }
        if !quote.paymentTerms.isEmpty {
            y = draw("Condiciones de pago", font: .boldSystemFont(ofSize: 11), at: y)
            y = draw(quote.paymentTerms, font: .systemFont(ofSize: 9), at: y)
            y += 8
        } else if !profile.terms.isEmpty {
            y = draw("Condiciones", font: .boldSystemFont(ofSize: 11), at: y)
            y = draw(profile.terms, font: .systemFont(ofSize: 9), at: y)
            y += 8
        }
        if !notesText(quote).isEmpty {
            y = draw("Notas", font: .boldSystemFont(ofSize: 11), at: y)
            y = draw(notesText(quote), font: .systemFont(ofSize: 9), at: y)
            y += 8
        }
        return y
    }

    private func notesText(_ quote: Quote) -> String {
        quote.notes
    }

    private func drawWatermark(in context: UIGraphicsPDFRendererContext) {
        let text = "PresupuestApp"
        let font = UIFont.systemFont(ofSize: 48, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.gray.withAlphaComponent(0.12)
        ]
        context.cgContext.saveGState()
        context.cgContext.translateBy(x: 180, y: 520)
        context.cgContext.rotate(by: -CGFloat.pi / 4)
        text.draw(at: .zero, withAttributes: attributes)
        context.cgContext.restoreGState()
    }

    // MARK: - Texto

    @discardableResult
    private func draw(_ text: String, font: UIFont, at y: CGFloat) -> CGFloat {
        let width = Self.pageRect.width - Self.margin * 2
        let box = CGRect(x: Self.margin, y: y, width: width, height: 800)
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 800),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        )
        draw(text, font: font, in: CGRect(x: box.minX, y: y, width: width, height: ceil(rect.height)), alignment: .left)
        return y + ceil(rect.height) + 2
    }

    private func draw(_ text: String, font: UIFont, in rect: CGRect, alignment: NSTextAlignment) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byTruncatingTail
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: UIColor.black,
                .paragraphStyle: style
            ]
        )
    }

    private func unitLabel(_ unit: MeasureUnit) -> String {
        switch unit {
        case .unit: return "ud"
        case .meter: return "m"
        case .squareMeter: return "m²"
        case .cubicMeter: return "m³"
        case .hour: return "h"
        case .lumpSum: return "pa"
        }
    }

    private func formatMoney(_ value: Decimal) -> String {
        Self.money.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func formatAmount(_ value: Decimal) -> String {
        Self.amount.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    /// Creados en cada uso: `NumberFormatter` y `DateFormatter` no son seguros
    /// entre hilos y el puerto `QuotePDFRenderer` es `Sendable` (los tests de
    /// AppTests corren en paralelo).
    private static var money: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_ES")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private static var amount: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_ES")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        return formatter
    }
}
