import Foundation
import Testing
@testable import QuoteCore

// Los helpers `d(_:)` y `makeUTCDate` vienen de Fakes.swift (compartidos en el target).

struct QuoteVectorTests {
    private func makeLine(quantity: Decimal, unitPrice: Decimal, vatRate: Decimal = d("21")) -> QuoteLine {
        QuoteLine(
            itemID: nil,
            name: "Item",
            unit: .unit,
            quantity: quantity,
            unitPrice: unitPrice,
            vatRate: vatRate,
            origin: .manual
        )
    }

    // Vector 1 de DOMAIN.md: 4 × 50,00 @21 % + 1 × 120,00 @21 %
    @Test func vector1() {
        let lines = [
            makeLine(quantity: d("4"), unitPrice: d("50.00")),
            makeLine(quantity: d("1"), unitPrice: d("120.00"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .none)
        #expect(totals.subtotal == d("320.00"))
        #expect(totals.discount == d("0.00"))
        #expect(totals.vatBreakdown.count == 1)
        #expect(totals.vatBreakdown[0].rate == d("21"))
        #expect(totals.vatBreakdown[0].base == d("320.00"))
        #expect(totals.vatBreakdown[0].vat == d("67.20"))
        #expect(totals.total == d("387.20"))
    }

    // Vector 2 de DOMAIN.md: 1 × 100,00 @21 % + 1 × 200,00 @10 %
    @Test func vector2() {
        let lines = [
            makeLine(quantity: d("1"), unitPrice: d("100.00"), vatRate: d("21")),
            makeLine(quantity: d("1"), unitPrice: d("200.00"), vatRate: d("10"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .none)
        #expect(totals.subtotal == d("300.00"))
        #expect(totals.total == d("341.00"))
        #expect(totals.vatBreakdown.count == 2)
        let rates = totals.vatBreakdown.map { $0.rate }
        #expect(rates.contains(d("21")))
        #expect(rates.contains(d("10")))
        let group21 = totals.vatBreakdown.first { $0.rate == d("21") }!
        let group10 = totals.vatBreakdown.first { $0.rate == d("10") }!
        #expect(group21.base == d("100.00"))
        #expect(group21.vat == d("21.00"))
        #expect(group10.base == d("200.00"))
        #expect(group10.vat == d("20.00"))
    }

    // Vector 3 de DOMAIN.md: 2,5 × 10,01 @21 % (25,025 redondea hacia arriba con .plain)
    @Test func vector3() {
        let line = makeLine(quantity: d("2.5"), unitPrice: d("10.01"))
        let calculator = QuoteCalculator()
        #expect(calculator.lineTotal(line) == d("25.03"))
        let totals = calculator.calculate(lines: [line], discount: .none)
        #expect(totals.vatBreakdown[0].vat == d("5.26"))
        #expect(totals.total == d("30.29"))
    }

    // Vector 4 de DOMAIN.md: vector 2 con descuento del 10 %
    @Test func vector4() {
        let lines = [
            makeLine(quantity: d("1"), unitPrice: d("100.00"), vatRate: d("21")),
            makeLine(quantity: d("1"), unitPrice: d("200.00"), vatRate: d("10"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .percent(d("10")))
        #expect(totals.discount == d("30.00"))
        #expect(totals.total == d("306.90"))
        let base21 = totals.vatBreakdown.first { $0.rate == d("21") }!.base
        let base10 = totals.vatBreakdown.first { $0.rate == d("10") }!.base
        #expect(base21 == d("90.00"))
        #expect(base10 == d("180.00"))
        let vat21 = totals.vatBreakdown.first { $0.rate == d("21") }!.vat
        let vat10 = totals.vatBreakdown.first { $0.rate == d("10") }!.vat
        #expect(vat21 == d("18.90"))
        #expect(vat10 == d("18.00"))
    }

    // Vector 5 de DOMAIN.md: descuento fijo 500,00 sobre subtotal 300,00 (nunca mayor que el subtotal)
    @Test func vector5() {
        let lines = [
            makeLine(quantity: d("1"), unitPrice: d("100.00"), vatRate: d("21")),
            makeLine(quantity: d("1"), unitPrice: d("200.00"), vatRate: d("10"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .amount(d("500.00")))
        #expect(totals.discount == d("300.00"))
        #expect(totals.total == d("0.00"))
    }

    // Vector 6 de DOMAIN.md: presupuesto sin líneas → DomainError.emptyQuote al enviarlo
    @Test func vector6() {
        let clock = FixedClock(date: makeUTCDate(2026, 3, 15))
        let quotes = FakeQuoteRepository()
        let profile = FakeProfileRepository()
        profile.profile = BusinessProfile(name: "Test", taxID: "1", phone: "1", email: "1", defaultVATRate: d("21"), terms: "", validityDays: 30, numberPrefix: "P")
        let entitlements = FixedEntitlements(plan: .free)
        let changeStatus = ChangeQuoteStatus(quotes: quotes)
        let quote = Quote(
            id: UUID(),
            number: "P-2026-0001",
            date: clock.now(),
            validityDays: 30,
            client: Client(),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: d("21")
        )
        quotes.save(quote)
        #expect(throws: DomainError.emptyQuote) {
            _ = try changeStatus.execute(quote, to: .sent)
        }
    }

    // Vector 7 de DOMAIN.md: reparto con resto de céntimos (5,00 sobre bases 200,00 @10 % y 100,00 @21 %)
    @Test func vector7() {
        let lines = [
            makeLine(quantity: d("1"), unitPrice: d("200.00"), vatRate: d("10")),
            makeLine(quantity: d("1"), unitPrice: d("100.00"), vatRate: d("21"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .amount(d("5.00")))
        #expect(totals.discount == d("5.00"))
        let group10 = totals.vatBreakdown.first { $0.rate == d("10") }!
        let group21 = totals.vatBreakdown.first { $0.rate == d("21") }!
        #expect(group10.base == d("196.67")) // 200,00 − 3,33
        #expect(group21.base == d("98.33"))  // 100,00 − 1,67
        #expect(group10.vat == d("19.67"))
        #expect(group21.vat == d("20.65"))
        #expect(totals.total == d("335.32"))
    }

    // Vector 8 de DOMAIN.md: descuento fijo menor que el subtotal (10,00 sobre 300,00)
    @Test func vector8() {
        let lines = [
            makeLine(quantity: d("1"), unitPrice: d("100.00"), vatRate: d("21")),
            makeLine(quantity: d("1"), unitPrice: d("200.00"), vatRate: d("10"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .amount(d("10.00")))
        #expect(totals.discount == d("10.00"))
        let group21 = totals.vatBreakdown.first { $0.rate == d("21") }!
        let group10 = totals.vatBreakdown.first { $0.rate == d("10") }!
        #expect(group21.base == d("96.67"))   // 100,00 − 3,33
        #expect(group10.base == d("193.33"))  // 200,00 − 6,67
        #expect(group21.vat == d("20.30"))
        #expect(group10.vat == d("19.33"))
        #expect(totals.total == d("329.63"))
    }

    // Vector 9 de DOMAIN.md: orden de reparto (0,01 sobre 150,00 @10 % + 150,00 @21 %)
    @Test func vector9() {
        let lines = [
            makeLine(quantity: d("1"), unitPrice: d("150.00"), vatRate: d("10")),
            makeLine(quantity: d("1"), unitPrice: d("150.00"), vatRate: d("21"))
        ]
        let calculator = QuoteCalculator()
        let totals = calculator.calculate(lines: lines, discount: .amount(d("0.01")))
        #expect(totals.discount == d("0.01"))
        let group10 = totals.vatBreakdown.first { $0.rate == d("10") }!
        let group21 = totals.vatBreakdown.first { $0.rate == d("21") }!
        #expect(group10.base == d("149.99")) // recibe 0,01
        #expect(group21.base == d("150.00")) // recibe 0,00
        #expect(group10.vat == d("15.00"))
        #expect(group21.vat == d("31.50"))
        #expect(totals.total == d("346.49"))
    }

    // Caso límite: cantidad 0 (la línea suma 0,00 y no rompe el resto)
    @Test func zeroQuantityLine() {
        let zero = makeLine(quantity: d("0"), unitPrice: d("10.00"))
        let normal = makeLine(quantity: d("1"), unitPrice: d("100.00"))
        let calculator = QuoteCalculator()
        #expect(calculator.lineTotal(zero) == d("0.00"))
        let totals = calculator.calculate(lines: [zero, normal], discount: .none)
        #expect(totals.subtotal == d("100.00"))
        #expect(totals.vatBreakdown.count == 1)
        #expect(totals.vatBreakdown[0].base == d("100.00"))
        #expect(totals.vatBreakdown[0].vat == d("21.00"))
        #expect(totals.total == d("121.00"))
    }

    // Caso límite: precio unitario con 4 decimales (1 × 10,5555 → línea 10,56)
    @Test func fourDecimalUnitPrice() {
        let line = makeLine(quantity: d("1"), unitPrice: d("10.5555"))
        let calculator = QuoteCalculator()
        #expect(calculator.lineTotal(line) == d("10.56"))
        let totals = calculator.calculate(lines: [line], discount: .none)
        #expect(totals.subtotal == d("10.56"))
        #expect(totals.vatBreakdown[0].base == d("10.56"))
        #expect(totals.vatBreakdown[0].vat == d("2.22"))
        #expect(totals.total == d("12.78"))
    }

    // DOMAIN.md: netPrice = round4(priceWithVAT / (1 + rate))
    @Test func netPriceRoundingPolicy() {
        #expect(RoundingPolicy.netPrice(fromGross: d("121.00"), vatRate: d("21")) == d("100.0000"))
        #expect(RoundingPolicy.netPrice(fromGross: d("25.00"), vatRate: d("21")) == d("20.6612"))
    }
}
