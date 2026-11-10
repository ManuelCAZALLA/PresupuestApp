import Foundation
import PDFKit
import QuoteCore
import UIKit

/// Genera el PDF A4 profesional del presupuesto en el dispositivo.
/// Diseño corporativo (fondo blanco, azul #194F91, tablas limpias), sin recalcular importes.
struct DeviceQuotePDFRenderer: QuotePDFRenderer {
    private static let pageRect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    private static let marginLeft: CGFloat = 39.7   // ~14 mm
    private static let marginRight: CGFloat = 39.7  // ~14 mm
    private static let marginTop: CGFloat = 36.9    // ~13 mm
    private static let marginBottom: CGFloat = 42.5 // ~15 mm

    private static let blue = UIColor(red: 25/255, green: 79/255, blue: 145/255, alpha: 1)          // #194F91
    private static let text = UIColor(red: 21/255, green: 29/255, blue: 43/255, alpha: 1)           // #151D2B
    private static let secondary = UIColor(red: 70/255, green: 82/255, blue: 102/255, alpha: 1)     // #465266
    private static let separator = UIColor(red: 229/255, green: 232/255, blue: 237/255, alpha: 1)   // #E5E8ED
    private static let summaryBG = UIColor(red: 246/255, green: 248/255, blue: 250/255, alpha: 1)   // #F6F8FA

    private static var contentWidth: CGFloat { pageRect.width - marginLeft - marginRight }
    private static var bottomLimit: CGFloat { pageRect.height - marginBottom }

    func render(
        quote: Quote,
        profile: BusinessProfile,
        totals: QuoteTotals,
        watermark: Bool
    ) throws -> URL {
        let showLineAmounts = quote.showLineAmounts ?? profile.showLineAmountsInPDF
        let plan = layoutPlan(quote: quote, profile: profile, totals: totals, showLineAmounts: showLineAmounts)
        let renderer = UIGraphicsPDFRenderer(bounds: Self.pageRect)
        let data = renderer.pdfData { context in
            for page in 0..<plan.pageCount {
                context.beginPage()
                if watermark { drawWatermark(in: context) }
                drawPage(page, plan: plan, quote: quote, profile: profile, totals: totals, showLineAmounts: showLineAmounts, in: context)
                drawFooter(page: page + 1, total: plan.pageCount)
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: quote))
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Layout planning (two-pass pagination)

    private struct LayoutPlan {
        var pageCount: Int
        var firstLinePage: [Int]      // page index per quote line
        var summaryPage: Int          // page index where summary starts
        var linesStartYByPage: [Int: CGFloat]
    }

    private func layoutPlan(quote: Quote, profile: BusinessProfile, totals: QuoteTotals, showLineAmounts: Bool) -> LayoutPlan {
        var page = 0
        var y = headerEndY(quote: quote, profile: profile)
        var firstLinePage: [Int] = Array(repeating: 0, count: quote.lines.count)
        var linesStartYByPage: [Int: CGFloat] = [:]

        if !quote.lines.isEmpty {
            y = max(y, Self.marginTop)
            if linesStartYByPage[page] == nil { linesStartYByPage[page] = y }
            y = y + Self.tableHeaderHeight
            let summaryReserve = summaryHeight(totals: totals)
            for (index, _) in quote.lines.enumerated() {
                let rowH = Self.rowHeight
                if y + rowH + summaryReserve > Self.bottomLimit - Self.footerReserve {
                    page += 1
                    y = Self.marginTop
                    linesStartYByPage[page] = y
                    y += Self.tableHeaderHeight
                }
                firstLinePage[index] = page
                y += rowH
            }
            // summary after last line
            let sHeight = summaryHeight(totals: totals)
            if y + 18 + sHeight > Self.bottomLimit - Self.footerReserve {
                page += 1
                y = Self.marginTop
            }
            let summaryPage = page
            let totalPages = page + 1
            return LayoutPlan(pageCount: totalPages, firstLinePage: firstLinePage, summaryPage: summaryPage, linesStartYByPage: linesStartYByPage)
        } else {
            let sHeight = summaryHeight(totals: totals)
            if y + 18 + sHeight > Self.bottomLimit - Self.footerReserve {
                page += 1
            }
            return LayoutPlan(pageCount: page + 1, firstLinePage: [], summaryPage: page, linesStartYByPage: [:])
        }
    }

    private func headerEndY(quote: Quote, profile: BusinessProfile) -> CGFloat {
        var y = Self.marginTop
        // header blocks
        var leftBottom = y
        if profile.logo.flatMap({ UIImage(data: $0) }) != nil {
            leftBottom += 70
        }
        leftBottom += lineHeight("x", font: .boldSystemFont(ofSize: 18)) + 2
        let leftLines = [profile.taxID, profile.address, profile.phone, profile.email].filter { !$0.isEmpty }.count
        leftBottom += CGFloat(leftLines) * (lineHeight("x", font: .systemFont(ofSize: 10.5)) + 2)

        var rightBottom = y + lineHeight("Presupuesto para", font: .systemFont(ofSize: 10.5)) + 4
        rightBottom += lineHeight(quote.client.name, font: .boldSystemFont(ofSize: 13)) + 2

        y = max(leftBottom, rightBottom) + 14
        y += lineHeight("PROPUESTA DE PRESUPUESTO", font: .boldSystemFont(ofSize: 28)) + 10
        y += 40 // 3 columns labels+values
        y += 10 // blue line spacing
        y += 18
        y += lineHeight("Descripción del Proyecto", font: .boldSystemFont(ofSize: 16)) + 6
        if !quote.workDescription.isEmpty {
            y += textHeight(quote.workDescription, font: .systemFont(ofSize: 11.5), width: Self.contentWidth) + 8
        }
        if !quote.notes.isEmpty {
            y += textHeight(quote.notes, font: .systemFont(ofSize: 11), width: Self.contentWidth) + 10
        }
        y += 14
        y += lineHeight("Partidas", font: .boldSystemFont(ofSize: 16)) + 8
        return y
    }

    private func summaryHeight(totals: QuoteTotals) -> CGFloat {
        // gray subtotal row + optional discount/vat rows + blue total bar
        var rows = 1 // subtotal
        if totals.discount > 0 { rows += 1 }
        // show IVA breakdown only when meaningful (matches totals data)
        rows += max(totals.vatBreakdown.count, 0)
        let rowH: CGFloat = 22
        let totalBar: CGFloat = 34
        return CGFloat(rows) * rowH + totalBar + 8
    }

    private static let tableHeaderHeight: CGFloat = 26
    private static let rowHeight: CGFloat = 24
    private static let footerReserve: CGFloat = 26

    // MARK: - Drawing

    private func drawPage(_ page: Int, plan: LayoutPlan, quote: Quote, profile: BusinessProfile, totals: QuoteTotals, showLineAmounts: Bool, in context: UIGraphicsPDFRendererContext) {
        var y = Self.marginTop
        if page == 0 {
            y = drawHeader(quote: quote, profile: profile, at: y)
            y = drawDescription(quote: quote, at: y)
            y = drawSectionTitle("Partidas", at: y)
        }

        // draw lines that belong to this page
        let lineIndices = quote.lines.indices.filter { plan.firstLinePage[$0] == page }
        if !lineIndices.isEmpty {
            let startY = page == 0 ? y : (plan.linesStartYByPage[page] ?? Self.marginTop)
            y = drawLinesBlock(lines: quote.lines, indices: Array(lineIndices), showLineAmounts: showLineAmounts, totals: totals, at: startY, context: context)
        } else if page == 0 && quote.lines.isEmpty {
            y = drawTableHeader(showLineAmounts: showLineAmounts, at: y, context: context)
        }

        if plan.summaryPage == page {
            if !quote.lines.isEmpty || page == 0 {
                // blue line after table
                y = max(y, lineIndices.isEmpty ? y : y)
                y += 6
                drawHLine(y: y, color: Self.blue, width: 1.5)
                y += 14
            } else {
                drawHLine(y: y, color: Self.blue, width: 1.5)
                y += 14
            }
            _ = drawSummary(totals: totals, at: y)
        }
    }

    private func drawHeader(quote: Quote, profile: BusinessProfile, at y: CGFloat) -> CGFloat {
        let startY = y
        var leftY = y
        if let logo = profile.logo.flatMap({ UIImage(data: $0) }) {
            let w: CGFloat = 105
            let h: CGFloat = 68
            logo.draw(in: CGRect(x: Self.marginLeft, y: leftY, width: w, height: h))
            leftY += h + 6
        }
        leftY = drawText(profile.name.isEmpty ? "—" : profile.name, font: .boldSystemFont(ofSize: 18), color: Self.text, x: Self.marginLeft, y: leftY, width: 280)
        for value in [profile.taxID, profile.address, profile.phone, profile.email].filter({ !$0.isEmpty }) {
            leftY = drawText(value, font: .systemFont(ofSize: 10.5), color: Self.secondary, x: Self.marginLeft, y: leftY, width: 280)
        }

        // right: "Presupuesto para" + client
        let rightW: CGFloat = 190
        let rightX = Self.pageRect.width - Self.marginRight - rightW
        var rightY = startY
        rightY = drawText("Presupuesto para", font: .systemFont(ofSize: 10.5), color: Self.secondary, x: rightX, y: rightY, width: rightW, align: .right)
        rightY = drawText(quote.client.name.isEmpty ? "—" : quote.client.name, font: .boldSystemFont(ofSize: 13), color: Self.text, x: rightX, y: rightY, width: rightW, align: .right)

        var y = max(leftY, rightY) + 14
        y = drawText("PROPUESTA DE PRESUPUESTO", font: .boldSystemFont(ofSize: 28), color: Self.blue, x: Self.marginLeft, y: y, width: Self.contentWidth)
        y += 6
        y = drawIDBlock(quote: quote, at: y)
        drawHLine(y: y, color: Self.blue, width: 1.5)
        return y + 18
    }

    private func drawIDBlock(quote: Quote, at y: CGFloat) -> CGFloat {
        let colW = Self.contentWidth / 3
        let labelFont = UIFont.boldSystemFont(ofSize: 10.5)
        let valueFont = UIFont.systemFont(ofSize: 12.5)
        let labels = ["Número de presupuesto:", "Fecha:", "Válido hasta:"]
        let dateStr = Self.dateFormatter.string(from: quote.issueDate)
        let until = Calendar.current.date(byAdding: .day, value: quote.validityDays, to: quote.issueDate)
        let untilStr = until.map { Self.dateFormatter.string(from: $0) } ?? "—"
        let values = [quote.number, dateStr, untilStr]
        for i in 0..<3 {
            let x = Self.marginLeft + CGFloat(i) * colW
            _ = drawText(labels[i], font: labelFont, color: Self.secondary, x: x, y: y, width: colW - 8)
            _ = drawText(values[i], font: valueFont, color: Self.text, x: x, y: y + 14, width: colW - 8)
        }
        return y + 40
    }

    private func drawDescription(quote: Quote, at y: CGFloat) -> CGFloat {
        var y = y
        y = drawSectionTitle("Descripción del Proyecto", at: y)
        if !quote.workDescription.isEmpty {
            y = drawText(quote.workDescription, font: .systemFont(ofSize: 11.5), color: Self.secondary, x: Self.marginLeft, y: y, width: Self.contentWidth)
            y += 6
        }
        if !quote.notes.isEmpty {
            let label = "Nota: "
            let full = label + quote.notes
            let attr = NSMutableAttributedString(string: full, attributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: Self.secondary
            ])
            attr.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 11), range: NSRange(location: 0, length: (label as NSString).length))
            let h = attr.boundingRect(with: CGSize(width: Self.contentWidth, height: 9999), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
            attr.draw(in: CGRect(x: Self.marginLeft, y: y, width: Self.contentWidth, height: ceil(h)))
            y += ceil(h) + 8
        }
        return y + 6
    }

    private func drawSectionTitle(_ title: String, at y: CGFloat) -> CGFloat {
        drawText(title, font: .boldSystemFont(ofSize: 16), color: Self.text, x: Self.marginLeft, y: y, width: Self.contentWidth) + 8
    }

    private func columns(showLineAmounts: Bool) -> [(String, CGFloat, NSTextAlignment)] {
        if showLineAmounts {
            return [("DESCRIPCIÓN", 280, .left), ("CANT.", 54, .right), ("PRECIO", 76, .right), ("TOTAL", 76, .right)]
        }
        return [("DESCRIPCIÓN", Self.contentWidth - 70, .left), ("CANT.", 62, .right)]
    }

    @discardableResult
    private func drawTableHeader(showLineAmounts: Bool, at y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let cols = columns(showLineAmounts: showLineAmounts)
        var x = Self.marginLeft
        for col in cols {
            _ = drawText(col.0, font: .boldSystemFont(ofSize: 10), color: Self.secondary, x: x, y: y, width: col.1, align: col.2)
            x += col.1 + 8
        }
        let lineY = y + 18
        drawHLine(y: lineY, color: Self.blue, width: 1.2)
        return lineY + 6
    }

    private func drawLinesBlock(lines: [QuoteLine], indices: [Int], showLineAmounts: Bool, totals: QuoteTotals, at y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = drawTableHeader(showLineAmounts: showLineAmounts, at: y, context: context)
        let cols = columns(showLineAmounts: showLineAmounts)
        let calculator = QuoteCalculator()
        for i in indices {
            let line = lines[i]
            let number = "\(i + 1). "
            let desc = number + line.name
            var values: [(String, NSTextAlignment)] = [(desc, .left), (formatAmount(line.quantity), .right)]
            if showLineAmounts {
                let total = calculator.lineTotal(line)
                values.append((formatMoney(line.unitPrice), .right))
                values.append((formatMoney(total), .right))
            }
            var x = Self.marginLeft
            for (idx, col) in cols.enumerated() {
                let font = idx == 0 ? UIFont.systemFont(ofSize: 11.5, weight: .semibold) : UIFont.systemFont(ofSize: 11)
                _ = drawText(values[idx].0, font: font, color: Self.text, x: x, y: y, width: col.1, align: col.2)
                x += col.1 + 8
            }
            let rowBottom = y + Self.rowHeight - 4
            drawHLine(y: rowBottom, color: Self.separator, width: 0.6)
            y += Self.rowHeight
        }
        return y
    }

    private func drawSummary(totals: QuoteTotals, at y: CGFloat) -> CGFloat {
        let blockW: CGFloat = 230
        let x = Self.pageRect.width - Self.marginRight - blockW
        var y = y
        let pad: CGFloat = 10

        func row(_ left: String, _ right: String, bg: UIColor?, textColor: UIColor, bold: Bool, fontSize: CGFloat, height: CGFloat) {
            if let bg {
                bg.setFill()
                UIBezierPath(rect: CGRect(x: x, y: y, width: blockW, height: height)).fill()
            }
            let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
            _ = drawText(left, font: font, color: textColor, x: x + pad, y: y + (height - font.lineHeight) / 2, width: blockW * 0.5, align: .left)
            _ = drawText(right, font: font, color: textColor, x: x + blockW * 0.45, y: y + (height - font.lineHeight) / 2, width: blockW * 0.55 - pad, align: .right)
            y += height
        }

        row("Subtotal", formatMoney(totals.subtotal), bg: Self.summaryBG, textColor: Self.secondary, bold: false, fontSize: 11.5, height: 24)
        if totals.discount > 0 {
            row("Descuento", "−\(formatMoney(totals.discount))", bg: Self.summaryBG, textColor: Self.secondary, bold: false, fontSize: 11.5, height: 24)
        }
        for group in totals.vatBreakdown {
            row("IVA \(formatAmount(group.rate)) %", formatMoney(group.vat), bg: Self.summaryBG, textColor: Self.secondary, bold: false, fontSize: 11, height: 22)
        }
        row("TOTAL:", formatMoney(totals.total), bg: Self.blue, textColor: .white, bold: true, fontSize: 15.5, height: 34)
        return y
    }

    private func drawFooter(page: Int, total: Int) {
        let y = Self.pageRect.height - Self.marginBottom + 6
        drawHLine(y: y, color: Self.separator, width: 0.8)
        let textY = y + 6
        _ = drawText("Gracias por su confianza.", font: .systemFont(ofSize: 11), color: Self.secondary, x: Self.marginLeft, y: textY, width: Self.contentWidth, align: .center)
        _ = drawText("\(page) / \(total)", font: .systemFont(ofSize: 10), color: Self.secondary, x: Self.marginLeft, y: textY, width: Self.contentWidth, align: .right)
    }

    private func drawWatermark(in context: UIGraphicsPDFRendererContext) {
        let text = "PresupuestApp"
        let font = UIFont.systemFont(ofSize: 48, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.gray.withAlphaComponent(0.10)
        ]
        context.cgContext.saveGState()
        context.cgContext.translateBy(x: 180, y: 520)
        context.cgContext.rotate(by: -CGFloat.pi / 4)
        text.draw(at: .zero, withAttributes: attributes)
        context.cgContext.restoreGState()
    }

    // MARK: - Primitives

    @discardableResult
    private func drawText(_ text: String, font: UIFont, color: UIColor, x: CGFloat, y: CGFloat, width: CGFloat, align: NSTextAlignment = .left) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
        let h = (text as NSString).boundingRect(with: CGSize(width: width, height: 9999), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil).height
        let height = max(ceil(h), ceil(font.lineHeight))
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: height), withAttributes: attrs)
        return y + height + 2
    }

    private func drawHLine(y: CGFloat, color: UIColor, width: CGFloat) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: CGPoint(x: Self.marginLeft, y: y))
        ctx.addLine(to: CGPoint(x: Self.pageRect.width - Self.marginRight, y: y))
        ctx.strokePath()
    }

    private func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let h = (text as NSString).boundingRect(with: CGSize(width: width, height: 9999), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil).height
        return ceil(h)
    }

    private func lineHeight(_ text: String, font: UIFont) -> CGFloat { ceil(font.lineHeight) }

    // MARK: - Formatting / helpers

    private func fileName(for quote: Quote) -> String {
        let client = quote.client.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = client.isEmpty ? "cliente" : client
        return "Presupuesto-\(quote.number)-\(suffix).pdf"
    }

    private func formatMoney(_ value: Decimal) -> String {
        Self.money.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func formatAmount(_ value: Decimal) -> String {
        Self.amount.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

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
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
}


