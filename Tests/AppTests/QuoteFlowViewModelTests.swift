import Foundation
import QuoteCore
import Testing
@testable import PresupuestApp

@Suite("ViewModels de presupuestos")
@MainActor
struct QuoteFlowViewModelTests {
    @Test("QuoteListViewModel crea y lista un presupuesto")
    func listCreatesQuote() throws {
        let quotes = MemoryQuoteRepository()
        let profile = MemoryProfileRepository()
        profile.profile = BusinessProfile(name: "Taller", numberPrefix: "P")
        let viewModel = QuoteListViewModel(
            listQuotes: ListQuotes(quotes: quotes),
            createQuote: CreateQuote(
                quotes: quotes,
                profile: profile,
                clock: FixedClock(date: Date(timeIntervalSince1970: 1_771_372_800)),
                entitlements: FixedPlan(.free)
            ),
            duplicateQuote: DuplicateQuote(
                quotes: quotes,
                profile: profile,
                clock: FixedClock(date: Date(timeIntervalSince1970: 1_771_372_800))
            )
        )

        let created = viewModel.create()
        #expect(created != nil)
        viewModel.load()
        #expect(viewModel.quotes.count == 1)
        #expect(viewModel.state == .loaded)
    }

    @Test("QuoteEditorViewModel suma cantidades con QuoteCalculator")
    func editorAddsLineAndTotals() throws {
        let quotes = MemoryQuoteRepository()
        let items = MemoryItemRepository()
        let item = Item(name: "Urinario PRUEBA", unitPrice: Decimal(50), vatRate: Decimal(21))
        try items.save(item)
        let quote = Quote(
            id: UUID(),
            number: "P-2026-0001",
            date: Date(),
            validityDays: 30,
            client: Client(),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
        try quotes.save(quote)

        let viewModel = QuoteEditorViewModel(
            quoteID: quote.id,
            loadQuote: LoadQuote(quotes: quotes),
            updateQuote: UpdateQuote(quotes: quotes),
            addLine: AddLine(quotes: quotes, items: items),
            updateLineQuantity: UpdateLineQuantity(quotes: quotes),
            removeLine: RemoveLine(quotes: quotes),
            listItems: ListItems(items: items)
        )
        viewModel.load()
        viewModel.addItem(item)
        viewModel.increase(try #require(viewModel.quote?.lines.first))
        #expect(viewModel.quote?.lines.first?.quantity == Decimal(2))
        #expect(viewModel.totals?.subtotal == Decimal(100))
        #expect(viewModel.totals?.total == Decimal(string: "121"))
    }
}

private struct FixedClock: Clock {
    let date: Date
    func now() -> Date { date }
}

private struct FixedPlan: EntitlementProvider {
    let plan: Plan
    init(_ plan: Plan) { self.plan = plan }
    func currentPlan() -> Plan { plan }
}

private final class MemoryQuoteRepository: QuoteRepository {
    var storage: [UUID: Quote] = [:]
    func all() throws -> [Quote] { Array(storage.values) }
    func quote(id: UUID) throws -> Quote? { storage[id] }
    func save(_ quote: Quote) throws { storage[quote.id] = quote }
    func delete(id: UUID) throws { storage[id] = nil }
}

private final class MemoryProfileRepository: ProfileRepository {
    var profile: BusinessProfile?
    func load() throws -> BusinessProfile? { profile }
    func save(_ profile: BusinessProfile) throws { self.profile = profile }
}

private final class MemoryItemRepository: ItemRepository {
    var storage: [UUID: Item] = [:]
    func all() throws -> [Item] { Array(storage.values) }
    func item(id: UUID) throws -> Item? { storage[id] }
    func item(named name: String) throws -> Item? {
        storage.values.first { $0.nameKey == Item.nameKey(name) }
    }
    func save(_ item: Item) throws { storage[item.id] = item }
    func delete(id: UUID) throws { storage[id] = nil }
}
