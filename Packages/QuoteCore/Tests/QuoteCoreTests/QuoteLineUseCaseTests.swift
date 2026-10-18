import Foundation
import Testing
@testable import QuoteCore

/// Reglas de líneas de presupuesto y de IVA por partida (docs/DOMAIN.md, M4b).
@Suite("Líneas de presupuesto")
struct QuoteLineUseCaseTests {
    private func makeQuote(defaultVATRate: Decimal = d("21")) -> Quote {
        Quote(
            id: UUID(),
            number: "P-2026-0001",
            date: makeUTCDate(2026, 10, 18),
            validityDays: 30,
            client: Client(name: "Cliente de prueba"),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: defaultVATRate
        )
    }

    private func makeItem(
        name: String = "Urinario",
        unit: MeasureUnit = .unit,
        price: Decimal = d("100"),
        vatRate: Decimal? = nil
    ) -> Item {
        Item(
            name: name,
            aliases: [],
            unit: unit,
            unitPrice: price,
            vatRate: vatRate,
            kind: .material,
            category: "Sanitarios",
            trade: .plumber
        )
    }

    @Test("AddLine usa el IVA de la partida cuando la tiene")
    func addLineUsesItemVAT() throws {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        let quote = makeQuote(defaultVATRate: d("21"))
        try quotes.save(quote)
        let item = makeItem(name: "Mano de obra", unit: .hour, price: d("30"), vatRate: d("10"))
        try items.save(item)

        let line = try AddLine(quotes: quotes, items: items)
            .execute(itemID: item.id, quantity: d("3"), in: quote.id)

        #expect(line.vatRate == d("10"))
        #expect(try quotes.quote(id: quote.id)?.lines == [line])
    }

    @Test("AddLine usa el IVA por defecto del presupuesto si la partida no tiene")
    func addLineFallsBackToQuoteVAT() throws {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        let quote = makeQuote(defaultVATRate: d("10"))
        try quotes.save(quote)
        let item = makeItem(vatRate: nil)
        try items.save(item)

        let line = try AddLine(quotes: quotes, items: items)
            .execute(itemID: item.id, quantity: d("1"), in: quote.id)

        #expect(line.vatRate == d("10"))
    }

    @Test("AddLine copia nombre, unidad y precio del momento")
    func addLineSnapshotsCatalog() throws {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        let quote = makeQuote()
        try quotes.save(quote)
        let item = makeItem(name: "Tubo multicapa 20 mm", unit: .meter, price: d("2.50"))
        try items.save(item)

        let line = try AddLine(quotes: quotes, items: items)
            .execute(itemID: item.id, quantity: d("10"), in: quote.id)

        #expect(line.itemID == item.id)
        #expect(line.name == "Tubo multicapa 20 mm")
        #expect(line.unit == .meter)
        #expect(line.quantity == d("10"))
        #expect(line.unitPrice == d("2.50"))
        #expect(line.origin == .manual)

        // Cambiar la partida después no toca la línea ya guardada.
        var changed = item
        changed.unitPrice = d("9")
        try items.save(changed)
        #expect(try quotes.quote(id: quote.id)?.lines.first?.unitPrice == d("2.50"))
    }

    @Test("AddLine de un presupuesto o una partida inexistentes lanza error")
    func addLineMissingEntities() {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        #expect(throws: DomainError.lineNotFound) {
            try AddLine(quotes: quotes, items: items)
                .execute(itemID: UUID(), quantity: d("1"), in: UUID())
        }
    }

    @Test("UpdateLineQuantity cambia solo la cantidad")
    func updateQuantity() throws {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        let quote = makeQuote()
        try quotes.save(quote)
        let item = makeItem(vatRate: d("10"))
        try items.save(item)
        let useCase = AddLine(quotes: quotes, items: items)
        let line = try useCase.execute(itemID: item.id, quantity: d("1"), in: quote.id)

        try UpdateLineQuantity(quotes: quotes)
            .execute(quoteID: quote.id, lineID: line.id, quantity: d("2.5"))

        let stored = try #require(try quotes.quote(id: quote.id)?.lines.first)
        #expect(stored.quantity == d("2.5"))
        #expect(stored.vatRate == d("10"))
        #expect(stored.unitPrice == d("100"))
    }

    @Test("UpdateLineQuantity de una línea que no existe lanza error")
    func updateMissingLine() {
        let quotes = FakeQuoteRepository()
        #expect(throws: DomainError.lineNotFound) {
            try UpdateLineQuantity(quotes: quotes)
                .execute(quoteID: UUID(), lineID: UUID(), quantity: d("1"))
        }
    }

    @Test("RemoveLine borra solo esa línea")
    func removeLine() throws {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        let quote = makeQuote()
        try quotes.save(quote)
        try items.save(makeItem(name: "Urinario"))
        try items.save(makeItem(name: "Inodoro", price: d("110")))
        let useCase = AddLine(quotes: quotes, items: items)
        let first = try useCase.execute(itemID: items.all()[0].id, quantity: d("1"), in: quote.id)
        _ = try useCase.execute(itemID: items.all()[1].id, quantity: d("1"), in: quote.id)

        try RemoveLine(quotes: quotes).execute(quoteID: quote.id, lineID: first.id)

        #expect(try quotes.quote(id: quote.id)?.lines.count == 1)
        #expect(try quotes.quote(id: quote.id)?.lines.first?.name == "Inodoro")
    }

    @Test("RemoveLine de una línea que no existe lanza error")
    func removeMissingLine() {
        let quotes = FakeQuoteRepository()
        #expect(throws: DomainError.lineNotFound) {
            try RemoveLine(quotes: quotes).execute(quoteID: UUID(), lineID: UUID())
        }
    }

    @Test("UpdateQuote guarda cliente, descuento, notas y líneas, pero no el estado")
    func updateQuote() throws {
        let quotes = FakeQuoteRepository()
        let original = makeQuote()
        try quotes.save(original)

        var edited = original
        edited.client = Client(name: "María Prueba", phone: "600 000 000")
        edited.discount = .percent(d("10"))
        edited.notes = "Prueba"
        edited.lines = [
            QuoteLine(
                name: "Urinario",
                unit: .unit,
                quantity: d("4"),
                unitPrice: d("100"),
                vatRate: d("21"),
                origin: .manual
            )
        ]
        edited.status = .accepted // el estado solo cambia con ChangeQuoteStatus

        try UpdateQuote(quotes: quotes).execute(edited)

        let stored = try #require(try quotes.quote(id: original.id))
        #expect(stored.client.name == "María Prueba")
        #expect(stored.discount == .percent(d("10")))
        #expect(stored.notes == "Prueba")
        #expect(stored.lines.count == 1)
        #expect(stored.status == .draft)
        #expect(stored.number == original.number)
        #expect(stored.date == original.date)
    }

    @Test("UpdateQuote de un presupuesto que no existe lanza error")
    func updateMissingQuote() {
        let quotes = FakeQuoteRepository()
        #expect(throws: DomainError.lineNotFound) {
            try UpdateQuote(quotes: quotes).execute(makeQuote())
        }
    }

    @Test("Líneas con tipos de IVA distintos: el desglose sale de QuoteCalculator")
    func mixedVATBreakdown() throws {
        let quotes = FakeQuoteRepository()
        let items = FakeItemRepository()
        let quote = makeQuote(defaultVATRate: d("21"))
        try quotes.save(quote)
        let labor = makeItem(name: "Mano de obra", unit: .hour, price: d("100"), vatRate: d("10"))
        let material = makeItem(name: "Urinario", price: d("100"), vatRate: nil)
        try items.save(labor)
        try items.save(material)

        let useCase = AddLine(quotes: quotes, items: items)
        _ = try useCase.execute(itemID: labor.id, quantity: d("1"), in: quote.id)
        _ = try useCase.execute(itemID: material.id, quantity: d("1"), in: quote.id)

        let lines = try #require(try quotes.quote(id: quote.id)?.lines)
        #expect(lines.map(\.vatRate) == [d("10"), d("21")])

        let totals = QuoteCalculator().calculate(lines: lines, discount: .none)
        #expect(totals.subtotal == d("200"))
        #expect(totals.vatBreakdown.map(\.rate) == [d("10"), d("21")])
        #expect(totals.vatBreakdown.map(\.vat) == [d("10"), d("21")])
        #expect(totals.total == d("231"))
    }
}
