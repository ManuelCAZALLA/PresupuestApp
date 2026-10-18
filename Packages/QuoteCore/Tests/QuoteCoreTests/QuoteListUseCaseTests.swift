import Foundation
import Testing
@testable import QuoteCore

@Suite("Listado y carga de presupuestos")
struct QuoteListUseCaseTests {
    @Test("ListQuotes ordena del más reciente al más antiguo")
    func listsNewestFirst() throws {
        let quotes = FakeQuoteRepository()
        let older = makeQuote(number: "P-2026-0001", date: makeUTCDate(2026, 1, 1))
        let newer = makeQuote(number: "P-2026-0002", date: makeUTCDate(2026, 10, 18))
        try quotes.save(older)
        try quotes.save(newer)

        let listed = try ListQuotes(quotes: quotes).execute()
        #expect(listed.map(\.number) == ["P-2026-0002", "P-2026-0001"])
    }

    @Test("LoadQuote lanza si el presupuesto no existe")
    func loadMissingThrows() {
        #expect(throws: DomainError.quoteNotFound) {
            try LoadQuote(quotes: FakeQuoteRepository()).execute(id: UUID())
        }
    }

    @Test("LoadQuote devuelve el presupuesto guardado")
    func loadExisting() throws {
        let quotes = FakeQuoteRepository()
        let quote = makeQuote(number: "P-2026-0001", date: makeUTCDate(2026, 10, 18))
        try quotes.save(quote)
        let loaded = try LoadQuote(quotes: quotes).execute(id: quote.id)
        #expect(loaded == quote)
    }

    private func makeQuote(number: String, date: Date) -> Quote {
        Quote(
            id: UUID(),
            number: number,
            date: date,
            validityDays: 30,
            client: Client(name: "Cliente de prueba"),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: d("21")
        )
    }
}
