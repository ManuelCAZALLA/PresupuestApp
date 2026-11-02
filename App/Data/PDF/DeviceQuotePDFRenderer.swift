import Foundation
import PDFKit
import QuoteCore
import UIKit

/// Genera el PDF A4 del presupuesto con diseño profesional.
struct DeviceQuotePDFRenderer: QuotePDFRenderer {
    private static let pageRect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    private static let margin: CGFloat = 30 // márgenes de 30 pt en el contenido

    func render(
        quote: Quote,
        profile: BusinessProfile,
        totals: QuoteTotals,
        watermark: Bool
    ) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: Self.pageRect)
        let showLineAmounts = quote.showLineAmounts ?? profile.showLineAmountsInPDF
        let accent = UIColor(hex: profile.accentColorHex) ?? UIColor(red: 47/255, green: 91/255, blue: 255/255, alpha: 1)
        
        // Calculamos anticipo
        let downPaymentPercent = quote.downPaymentPercent ?? profile.defaultDownPaymentPercent
        let downPaymentCalc = CalculateDownPayment()
        let downPayment = downPaymentPercent > 0 ? downPaymentCalc.execute(totalWithVAT: totals.total, percent: downPaymentPercent) : nil

        let data = renderer.pdfData { context in
            var pageNumber = 0
            func beginNewPage() {
                context.beginPage()
                pageNumber += 1
                if watermark {
                    drawWatermark(in: context)
                }
                drawFooter(pageNumber: pageNumber, totalPages: 0, profile: profile)
            }
            func updateFooterTotalPages(_ total: Int) {
                // We'll redraw footer conceptually by tracking
            }
            
            beginNewPage()
            var cursor = Self.margin
            
            // Cabecera con color de acento
            cursor = drawHeader(profile: profile, quote: quote, accent: accent, at: cursor)
            
            // Fila de tres cajas
            cursor = drawInfoBoxes(quote: quote, at: cursor)
            
            // Bloques "Presupuesto para" (cliente) y "Obra"
            cursor = drawParties(quote: quote, at: cursor)
            
            // Descripción de los trabajos
            if !quote.workDescription.isEmpty {
                cursor = drawSectionTitle("Descripción de los trabajos", accent: accent, at: cursor)
                cursor = drawTextBlock(quote.workDescription, at: cursor)
                cursor += 6
            }
            
            // Tabla de partidas
            let tableResult = drawLinesTable(
                quote: quote,
                context: context,
                startY: cursor,
                showLineAmounts: showLineAmounts,
                watermark: watermark,
                profile: profile,
                totals: totals,
                downPayment: downPayment,
                accent: accent
            )
            cursor = tableResult.cursor
            _ = tableResult.pagesUsed
            
            // Si estamos muy cerca del final y hay mucho que poner, ya manejado en tabla
            // Zona de pago + totales (mantenidos juntos)
            cursor = drawPaymentAndTotals(
                totals: totals,
                downPayment: downPayment,
                quote: quote,
                profile: profile,
                context: context,
                at: cursor,
                watermark: watermark,
                accent: accent
            )
            
            // Alcance y exclusiones en dos columnas lado a lado cuando haya espacio
            if !quote.scopeOfWork.isEmpty && !quote.exclusions.isEmpty {
                let width = Self.pageRect.width - Self.margin * 2
                let colW = (width - 12) / 2
                let scopeH = textHeight(for: quote.scopeOfWork, font: .systemFont(ofSize: 9), width: colW - 12)
                let exclH = textHeight(for: quote.exclusions, font: .systemFont(ofSize: 9), width: colW - 12)
                let h = max(40, max(scopeH, exclH) + 30)
                let rect1 = CGRect(x: Self.margin, y: cursor, width: colW, height: h)
                let rect2 = CGRect(x: Self.margin + colW + 12, y: cursor, width: colW, height: h)
                UIColor.systemGray6.withAlphaComponent(0.2).setFill()
                UIBezierPath(roundedRect: rect1, cornerRadius: 6).fill()
                UIBezierPath(roundedRect: rect2, cornerRadius: 6).fill()
                UIColor.systemGray4.setStroke()
                UIBezierPath(roundedRect: rect1, cornerRadius: 6).stroke()
                UIBezierPath(roundedRect: rect2, cornerRadius: 6).stroke()
                var cy = cursor + 6
                cy = drawText("Alcance", font: .boldSystemFont(ofSize: 9), atX: Self.margin + 6, atY: cy, width: colW - 12, alignment: .left)
                _ = drawText(quote.scopeOfWork, font: .systemFont(ofSize: 9), atX: Self.margin + 6, atY: cy, width: colW - 12, alignment: .left)
                var cy2 = cursor + 6
                cy2 = drawText("Exclusiones", font: .boldSystemFont(ofSize: 9), atX: Self.margin + colW + 12 + 6, atY: cy2, width: colW - 12, alignment: .left)
                _ = drawText(quote.exclusions, font: .systemFont(ofSize: 9), atX: Self.margin + colW + 12 + 6, atY: cy2, width: colW - 12, alignment: .left)
                cursor += h + 12
            } else {
                if !quote.scopeOfWork.isEmpty {
                    cursor = drawSectionTitle("Alcance", accent: accent, at: cursor)
                    cursor = drawTextBlock(quote.scopeOfWork, at: cursor)
                    cursor += 6
                }
                if !quote.exclusions.isEmpty {
                    cursor = drawSectionTitle("Exclusiones", accent: accent, at: cursor)
                    cursor = drawTextBlock(quote.exclusions, at: cursor)
                    cursor += 6
                }
            }
            
            // Bloque de aceptación del cliente
            cursor = drawAcceptanceBlock(at: cursor, accent: accent)
            
            // Añadir pie a todas las páginas
            let totalPages = pageNumber
            // Redibujar pies es complejo en UIGraphicsPDFRenderer; el pie se dibuja al crear página
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: quote))
        try data.write(to: url, options: .atomic)
        return url
    }

    private func fileName(for quote: Quote) -> String {
        let client = quote.client.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = client.isEmpty ? "cliente" : client
        return "Presupuesto-\(quote.number)-\(suffix).pdf"
    }
    
    private func drawHeader(profile: BusinessProfile, quote: Quote, accent: UIColor, at y: CGFloat) -> CGFloat {
        var y = y
        // Banda de color de acento a todo el ancho
        let barRect = CGRect(x: 0, y: y, width: Self.pageRect.width, height: 48)
        accent.setFill()
        UIBezierPath(rect: barRect).fill()
        
        let textColor = contrastingTextColor(for: accent)
        var headerY = y + 10
        
        let leftX = Self.margin
        if let logo = profile.logo.flatMap({ UIImage(data: $0) }) {
            let size = CGSize(width: 36, height: 36)
            logo.draw(in: CGRect(x: leftX, y: y + 6, width: size.width, height: size.height))
            headerY = y + 8
        } else {
            headerY = y + 14
        }
        
        // Datos del negocio en 2-3 líneas (10-11 pt)
        var businessLines: [String] = []
        if !profile.name.isEmpty { businessLines.append(profile.name) }
        var line2 = ""
        if !profile.address.isEmpty { line2 += profile.address }
        if !profile.taxID.isEmpty { line2 += line2.isEmpty ? profile.taxID : " · \(profile.taxID)" }
        if !line2.isEmpty { businessLines.append(line2) }
        var line3 = ""
        if !profile.phone.isEmpty { line3 += profile.phone }
        if !profile.email.isEmpty { line3 += line3.isEmpty ? profile.email : " · \(profile.email)" }
        if !line3.isEmpty { businessLines.append(line3) }
        
        let startX = (profile.logo != nil) ? leftX + 44 : leftX
        var by = headerY
        for (i, l) in businessLines.prefix(3).enumerated() {
            let font: UIFont = i == 0 ? .boldSystemFont(ofSize: 11) : .systemFont(ofSize: 10)
            _ = drawText(l, font: font, atX: startX, atY: by, width: Self.pageRect.width * 0.6 - startX, alignment: .left, color: textColor)
            by += 12
        }
        
        // Derecha: PRESUPUESTO + Nº
        let rightText = "PRESUPUESTO  Nº \(quote.number)"
        _ = drawText(rightText, font: .boldSystemFont(ofSize: 14), atX: Self.pageRect.width * 0.55, atY: y + 18, width: Self.pageRect.width - Self.pageRect.width * 0.55 - Self.margin, alignment: .right, color: textColor)
        
        y = barRect.maxY + 12
        return y
    }
    
    private func contrastingTextColor(for color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
            return luminance > 0.179 ? .black : .white
        }
        return .white
    }
    
    private func drawInfoBoxes(quote: Quote, at y: CGFloat) -> CGFloat {
        var y = y
        let boxWidth = (Self.pageRect.width - Self.margin * 2 - 12) / 3
        let boxes = [
            ("FECHA", Self.dateFormatter.string(from: quote.issueDate)),
            ("VÁLIDO HASTA", {
                if let until = Calendar.current.date(byAdding: .day, value: quote.validityDays, to: quote.issueDate) {
                    return Self.dateFormatter.string(from: until)
                }
                return "-"
            }()),
            ("CONDICIONES", quote.paymentTerms.isEmpty ? "Ver condiciones" : quote.paymentTerms)
        ]
        var maxHeight: CGFloat = 40
        var x = Self.margin
        for box in boxes {
            let textHeight = textHeight(for: box.1, font: .systemFont(ofSize: 9), width: boxWidth - 12)
            let height = max(40, textHeight + 24)
            if height > maxHeight { maxHeight = height }
        }
        x = Self.margin
        for box in boxes {
            let textHeight = textHeight(for: box.1, font: .systemFont(ofSize: 9), width: boxWidth - 12)
            let height = max(40, textHeight + 24)
            let rect = CGRect(x: x, y: y, width: boxWidth, height: height)
            UIColor.systemGray5.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
            UIColor.systemGray4.setStroke()
            UIBezierPath(roundedRect: rect, cornerRadius: 6).stroke()
            drawText(box.0, font: .boldSystemFont(ofSize: 8), atX: x + 6, atY: y + 6, width: boxWidth - 12, alignment: .left)
            _ = drawText(box.1, font: .systemFont(ofSize: 9), atX: x + 6, atY: y + 18, width: boxWidth - 12, alignment: .left)
            x += boxWidth + 6
        }
        return y + maxHeight + 8
    }
    
    private func textHeight(for text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
        let rect = (text as NSString).boundingRect(with: CGSize(width: width, height: 1000), options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        return ceil(rect.height)
    }
    
    private func drawParties(quote: Quote, at y: CGFloat) -> CGFloat {
        var y = y
        let leftW = (Self.pageRect.width - Self.margin * 2 - 12) / 2
        // Presupuesto para
        let rect1 = CGRect(x: Self.margin, y: y, width: leftW, height: 60)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: rect1, cornerRadius: 6).fill()
        UIColor.systemGray4.setStroke()
        UIBezierPath(roundedRect: rect1, cornerRadius: 6).stroke()
        var ly = y + 6
        ly = drawText("Presupuesto para", font: .boldSystemFont(ofSize: 9), atX: Self.margin + 6, atY: ly, width: leftW - 12, alignment: .left)
        ly = drawText(quote.client.name.isEmpty ? "—" : quote.client.name, font: .systemFont(ofSize: 9), atX: Self.margin + 6, atY: ly, width: leftW - 12, alignment: .left)
        if !quote.client.phone.isEmpty {
            ly = drawText(quote.client.phone, font: .systemFont(ofSize: 9), atX: Self.margin + 6, atY: ly, width: leftW - 12, alignment: .left)
        }
        if !quote.client.address.isEmpty {
            ly = drawText(quote.client.address, font: .systemFont(ofSize: 9), atX: Self.margin + 6, atY: ly, width: leftW - 12, alignment: .left)
        }
        
        // Obra
        let rect2 = CGRect(x: Self.margin + leftW + 12, y: y, width: leftW, height: 60)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: rect2, cornerRadius: 6).fill()
        UIColor.systemGray4.setStroke()
        UIBezierPath(roundedRect: rect2, cornerRadius: 6).stroke()
        var ry = y + 6
        ry = drawText("Obra", font: .boldSystemFont(ofSize: 9), atX: Self.margin + leftW + 12 + 6, atY: ry, width: leftW - 12, alignment: .left)
        if !quote.title.isEmpty {
            ry = drawText(quote.title, font: .systemFont(ofSize: 9), atX: Self.margin + leftW + 12 + 6, atY: ry, width: leftW - 12, alignment: .left)
        }
        if let workAddr = quote.client.workAddress, !workAddr.isEmpty && !workAddr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ry = drawText(workAddr, font: .systemFont(ofSize: 9), atX: Self.margin + leftW + 12 + 6, atY: ry, width: leftW - 12, alignment: .left)
        }
        // Si no hay dirección de obra, no dejamos espacio vacío - ya no añadimos líneas extra
        return y + 70
    }
    
    private func drawSectionTitle(_ title: String, accent: UIColor, at y: CGFloat) -> CGFloat {
        var y = y
        let rect = CGRect(x: Self.margin, y: y, width: 200, height: 16)
        accent.withAlphaComponent(0.1).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 3).fill()
        drawText(title, font: .boldSystemFont(ofSize: 9), atX: Self.margin + 6, atY: y + 3, width: 188, alignment: .left)
        return y + 22
    }
    
    private func drawTextBlock(_ text: String, at y: CGFloat) -> CGFloat {
        drawText(text, font: .systemFont(ofSize: 9), atX: Self.margin, atY: y, width: Self.pageRect.width - Self.margin * 2, alignment: .left)
    }
    
    private func drawLinesTable(
        quote: Quote,
        context: UIGraphicsPDFRendererContext,
        startY: CGFloat,
        showLineAmounts: Bool,
        watermark: Bool,
        profile: BusinessProfile,
        totals: QuoteTotals,
        downPayment: DownPaymentResult?,
        accent: UIColor
    ) -> (cursor: CGFloat, pagesUsed: Int) {
        var y = startY
        var pagesUsed = 1
        let width = Self.pageRect.width - Self.margin * 2
        // Columnas: Nº, Descripción, Ud., Cant. (+ precios si activado)
        var colX: [CGFloat] = []
        colX.append(Self.margin) // Nº
        if showLineAmounts {
            // Con precios
            colX.append(Self.margin + 25) // Descripción
            colX.append(Self.margin + width - 170) // Ud
            colX.append(Self.margin + width - 130) // Cant
            colX.append(Self.margin + width - 80) // Precio
            colX.append(Self.margin + width - 40) // Total
        } else {
            colX.append(Self.margin + 25) // Descripción
            colX.append(Self.margin + width - 90) // Ud
            colX.append(Self.margin + width - 50) // Cant
        }
        
        // Cabecera
        func drawHeaderRow(at rowY: CGFloat) -> CGFloat {
            let headerRect = CGRect(x: Self.margin, y: rowY, width: width, height: 18)
            accent.setFill()
            UIBezierPath(rect: headerRect).fill()
            drawText("Nº", font: .boldSystemFont(ofSize: 8), atX: Self.margin + 2, atY: rowY + 5, width: 23, alignment: .center)
            drawText("Descripción", font: .boldSystemFont(ofSize: 8), atX: colX[1] + 2, atY: rowY + 5, width: showLineAmounts ? (colX[2] - colX[1] - 4) : (colX[2] - colX[1] - 4), alignment: .left)
            drawText("Ud.", font: .boldSystemFont(ofSize: 8), atX: colX[showLineAmounts ? 2 : 2] - 2, atY: rowY + 5, width: 36, alignment: .right)
            drawText("Cant.", font: .boldSystemFont(ofSize: 8), atX: colX[showLineAmounts ? 3 : 3] - 2, atY: rowY + 5, width: showLineAmounts ? 48 : 48, alignment: .right)
            if showLineAmounts {
                drawText("Precio", font: .boldSystemFont(ofSize: 8), atX: colX[4] - 2, atY: rowY + 5, width: 38, alignment: .right)
                drawText("Total", font: .boldSystemFont(ofSize: 8), atX: colX[5] - 2, atY: rowY + 5, width: 38, alignment: .right)
            }
            return rowY + 22
        }
        
        y = drawHeaderRow(at: y)
        let calculator = QuoteCalculator()
        
        for (idx, line) in quote.lines.enumerated() {
            let needed: CGFloat = 18
            if y + needed + 150 > Self.pageRect.height - Self.margin { // reservar espacio para totales+aceptación
                context.beginPage()
                pagesUsed += 1
                if watermark { drawWatermark(in: context) }
                drawFooter(pageNumber: pagesUsed, totalPages: 0, profile: profile)
                y = Self.margin
                y = drawHeaderRow(at: y)
            }
            // Filas alternas
            if idx % 2 == 1 {
                let rowRect = CGRect(x: Self.margin, y: y - 1, width: width, height: 16)
                UIColor.systemGray6.withAlphaComponent(0.5).setFill()
                UIBezierPath(rect: rowRect).fill()
            }
            drawText("\(idx + 1)", font: .systemFont(ofSize: 8), atX: Self.margin + 2, atY: y, width: 23, alignment: .center)
            drawText(line.name, font: .systemFont(ofSize: 8), atX: colX[1] + 2, atY: y, width: showLineAmounts ? (colX[2] - colX[1] - 4) : (colX[2] - colX[1] - 4), alignment: .left)
            drawText(unitLabel(line.unit), font: .systemFont(ofSize: 8), atX: (showLineAmounts ? colX[2] - 2 : colX[2] - 2), atY: y, width: 36, alignment: .right)
            drawText(formatAmount(line.quantity), font: .systemFont(ofSize: 8), atX: (showLineAmounts ? colX[3] - 2 : colX[3] - 2), atY: y, width: showLineAmounts ? 48 : 48, alignment: .right)
            if showLineAmounts {
                drawText(formatMoney(line.unitPrice), font: .systemFont(ofSize: 8), atX: colX[4] - 2, atY: y, width: 38, alignment: .right)
                let total = calculator.lineTotal(line)
                drawText(formatMoney(total), font: .systemFont(ofSize: 8), atX: colX[5] - 2, atY: y, width: 38, alignment: .right)
            }
            y += 16
        }
        return (y + 10, pagesUsed)
    }
    
    private func drawPaymentAndTotals(
        totals: QuoteTotals,
        downPayment: DownPaymentResult?,
        quote: Quote,
        profile: BusinessProfile,
        context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        watermark: Bool,
        accent: UIColor
    ) -> CGFloat {
        var y = y
        let blockHeight: CGFloat = downPayment != nil ? 140 : 110
        if y + blockHeight > Self.pageRect.height - Self.margin - 80 {
            context.beginPage()
            if watermark { drawWatermark(in: context) }
            drawFooter(pageNumber: 99, totalPages: 0, profile: profile) // placeholder
            y = Self.margin
        }
        let width = Self.pageRect.width - Self.margin * 2
        // Zona de pago a la izquierda
        if downPayment != nil || !quote.paymentTerms.isEmpty || (profile.iban != nil && !(profile.iban!.isEmpty)) {
            var payHeight: CGFloat = 50
            if !quote.paymentTerms.isEmpty {
                payHeight += textHeight(for: quote.paymentTerms, font: .systemFont(ofSize: 8), width: width * 0.48 - 12) + 4
            }
            if let iban = profile.iban, !iban.isEmpty {
                payHeight += 12
            }
            if downPayment != nil {
                payHeight += 24
            }
            let payRect = CGRect(x: Self.margin, y: y, width: width * 0.48, height: max(60, payHeight))
            UIColor.systemGray6.withAlphaComponent(0.3).setFill()
            UIBezierPath(roundedRect: payRect, cornerRadius: 6).fill()
            UIColor.systemGray4.setStroke()
            UIBezierPath(roundedRect: payRect, cornerRadius: 6).stroke()
            var py = y + 6
            py = drawText("Forma de pago", font: .boldSystemFont(ofSize: 9), atX: Self.margin + 6, atY: py, width: width * 0.48 - 12, alignment: .left)
            if !quote.paymentTerms.isEmpty {
                py = drawText(quote.paymentTerms, font: .systemFont(ofSize: 8), atX: Self.margin + 6, atY: py, width: width * 0.48 - 12, alignment: .left)
                py += 4
            }
            if let iban = profile.iban, !iban.isEmpty {
                py = drawText("IBAN: \(iban)", font: .systemFont(ofSize: 8), atX: Self.margin + 6, atY: py, width: width * 0.48 - 12, alignment: .left)
                py += 2
            }
            if let dp = downPayment {
                py = drawText(String(format: "Anticipo %d%%: %@", Int(truncating: NSDecimalNumber(decimal: dp.percent)), formatMoney(dp.amount)), font: .systemFont(ofSize: 8), atX: Self.margin + 6, atY: py, width: width * 0.48 - 12, alignment: .left)
                py = drawText("Resto: \(formatMoney(dp.remainder))", font: .systemFont(ofSize: 8), atX: Self.margin + 6, atY: py, width: width * 0.48 - 12, alignment: .left)
            }
        }
        // Totales a la derecha
        let totX = Self.margin + width * 0.52
        var ty = y
        ty = drawText("Subtotal", font: .systemFont(ofSize: 9), atX: totX, atY: ty, width: width * 0.28, alignment: .left)
        _ = drawText(formatMoney(totals.subtotal), font: .systemFont(ofSize: 9), atX: totX + width * 0.28, atY: ty, width: width * 0.2, alignment: .right)
        ty += 16
        if totals.discount > 0 {
            ty = drawText("Descuento", font: .systemFont(ofSize: 9), atX: totX, atY: ty, width: width * 0.28, alignment: .left)
            _ = drawText("−\(formatMoney(totals.discount))", font: .systemFont(ofSize: 9), atX: totX + width * 0.28, atY: ty, width: width * 0.2, alignment: .right)
            ty += 16
        }
        for group in totals.vatBreakdown {
            ty = drawText("IVA \(formatAmount(group.rate)) %", font: .systemFont(ofSize: 9), atX: totX, atY: ty, width: width * 0.28, alignment: .left)
            _ = drawText(formatMoney(group.vat), font: .systemFont(ofSize: 9), atX: totX + width * 0.28, atY: ty, width: width * 0.2, alignment: .right)
            ty += 16
        }
        ty += 6
        let totalRect = CGRect(x: totX - 6, y: ty - 2, width: width * 0.48 + 12, height: 26)
        accent.setFill()
        UIBezierPath(roundedRect: totalRect, cornerRadius: 4).fill()
        drawText("Total", font: .boldSystemFont(ofSize: 11), atX: totX + 6, atY: ty + 5, width: width * 0.28, alignment: .left, color: .white)
        _ = drawText(formatMoney(totals.total), font: .boldSystemFont(ofSize: 11), atX: totX + width * 0.28 + 6, atY: ty + 5, width: width * 0.2 - 12, alignment: .right, color: .white)
        ty += 36
        return max(y + blockHeight, ty) + 10
    }
    
    private func drawAcceptanceBlock(at y: CGFloat, accent: UIColor) -> CGFloat {
        var y = y + 10
        if y > Self.pageRect.height - Self.margin - 60 {
            y = Self.margin + 20
        }
        let width = Self.pageRect.width - Self.margin * 2
        drawText("Aceptación del cliente", font: .boldSystemFont(ofSize: 10), atX: Self.margin, atY: y, width: width, alignment: .left)
        y += 16
        drawText("Nombre y apellidos: _____________________________", font: .systemFont(ofSize: 9), atX: Self.margin, atY: y, width: width, alignment: .left)
        y += 14
        drawText("Fecha: _____________________________", font: .systemFont(ofSize: 9), atX: Self.margin, atY: y, width: width, alignment: .left)
        y += 14
        drawText("Firma: _____________________________", font: .systemFont(ofSize: 9), atX: Self.margin, atY: y, width: width, alignment: .left)
        return y + 20
    }
    
    private func drawFooter(pageNumber: Int, totalPages: Int, profile: BusinessProfile) {
        let y = Self.pageRect.height - Self.margin + 8
        drawText("Creado con PresupuestApp", font: .systemFont(ofSize: 7), atX: Self.margin, atY: y, width: Self.pageRect.width - Self.margin * 2 - 80, alignment: .left)
        drawText("Página \(pageNumber) de \(totalPages == 0 ? pageNumber : totalPages)", font: .systemFont(ofSize: 7), atX: Self.margin, atY: y, width: Self.pageRect.width - Self.margin * 2, alignment: .right)
    }
    
    private func drawWatermark(in context: UIGraphicsPDFRendererContext) {
        let text = "PresupuestApp"
        let font = UIFont.systemFont(ofSize: 16, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.gray.withAlphaComponent(0.04)
        ]
        context.cgContext.saveGState()
        // Muy discreta, sin diagonal gigante
        text.draw(at: CGPoint(x: Self.margin, y: Self.pageRect.height - 40), withAttributes: attributes)
        context.cgContext.restoreGState()
    }
    
    @discardableResult
    private func drawText(_ text: String, font: UIFont, atX x: CGFloat, atY y: CGFloat, width: CGFloat, alignment: NSTextAlignment, color: UIColor = .black) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
        let rect = CGRect(x: x, y: y, width: width, height: 1000)
        let size = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 1000),
            options: [.usesLineFragmentOrigin],
            attributes: attributes,
            context: nil
        )
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: ceil(size.height)), withAttributes: attributes)
        return y + ceil(size.height) + 2
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

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
