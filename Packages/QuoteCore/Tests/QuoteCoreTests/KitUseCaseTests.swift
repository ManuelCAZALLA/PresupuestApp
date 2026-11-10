import Foundation
import Testing
@testable import QuoteCore

struct KitUseCaseTests {
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

    private func makeItem(name: String = "Item", price: Decimal = d("10.00"), vat: Decimal? = nil) -> Item {
        Item(name: name, unit: .unit, unitPrice: price, vatRate: vat, kind: .material)
    }

    @Test func manageKitsCreateUpdateDelete() throws {
        let repo = FakeKitRepository()
        let manage = ManageKits(kits: repo)
        #expect(try repo.all().isEmpty)

        let kit = Kit(name: "Instalación", entries: [])
        try manage.execute(.create(kit))
        #expect(try repo.all().count == 1)

        var edited = kit
        edited.name = "Instalación completa"
        try manage.execute(.update(edited))
        #expect(try repo.kit(id: kit.id)?.name == "Instalación completa")

        try manage.execute(.delete(kit.id))
        #expect(try repo.all().isEmpty)
    }

    @Test func addKitToQuoteAddsSnapshotLinesWithKitOrigin() throws {
        let items = FakeItemRepository()
        let kits = FakeKitRepository()
        let quotes = FakeQuoteRepository()
        let itemA = makeItem(name: "Aire acondicionado", price: d("500.00"), vat: d("21"))
        let itemB = makeItem(name: "Mano de obra", price: d("40.00"), vat: nil)
        try items.save(itemA)
        try items.save(itemB)

        let kit = Kit(name: "Pack AC", entries: [
            KitEntry(itemID: itemA.id, quantity: d("1")),
            KitEntry(itemID: itemB.id, quantity: d("1.5"))
        ])
        try kits.save(kit)

        let quote = makeQuote(defaultVATRate: d("10"))
        try quotes.save(quote)

        let added = try AddKitToQuote(quotes: quotes, items: items, kits: kits)
            .execute(kitID: kit.id, in: quote.id)

        #expect(added.count == 2)
        #expect(added.allSatisfy { $0.origin == .kit })
        #expect(added[0].name == "Aire acondicionado")
        #expect(added[0].unitPrice == d("500.00"))
        #expect(added[0].vatRate == d("21"))
        #expect(added[1].name == "Mano de obra")
        #expect(added[1].quantity == d("1.5"))
        #expect(added[1].vatRate == d("10")) // fallback al del presupuesto

        let stored = try #require(try quotes.quote(id: quote.id))
        #expect(stored.lines.count == 2)
    }

    @Test func addKitThrowsWhenKitOrQuoteMissing() throws {
        let items = FakeItemRepository()
        let kits = FakeKitRepository()
        let quotes = FakeQuoteRepository()
        let useCase = AddKitToQuote(quotes: quotes, items: items, kits: kits)

        #expect(throws: DomainError.quoteNotFound) {
            try useCase.execute(kitID: UUID(), in: UUID())
        }

        let quote = makeQuote()
        try quotes.save(quote)
        #expect(throws: DomainError.kitNotFound) {
            try useCase.execute(kitID: UUID(), in: quote.id)
        }
    }
}
