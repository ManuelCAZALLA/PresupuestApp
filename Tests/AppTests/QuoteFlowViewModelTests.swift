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
            ),
            deleteQuote: DeleteQuote(quotes: quotes)
        )

        let created = viewModel.create()
        #expect(created != nil)
        viewModel.load()
        #expect(viewModel.quotes.count == 1)
        #expect(viewModel.state == .loaded)
    }

    @Test("Duplicating puts the new draft first and exposes brief feedback")
    func duplicatePutsNewDraftFirst() {
        let date = Date(timeIntervalSince1970: 1_771_372_800)
        let original = makeListQuote(number: "P-2026-0001", date: date.addingTimeInterval(-60), status: .sent)
        let duplicate = makeListQuote(number: "P-2026-0002", date: date, status: .draft)
        let quotes = FakeListQuotes(quotes: [original])
        let duplicateUseCase = FakeDuplicateQuote(quotes: quotes, result: duplicate)
        let viewModel = makeViewModel(quotes: quotes, duplicate: duplicateUseCase)

        viewModel.load()
        viewModel.duplicate(original)

        #expect(viewModel.quotes.first?.id == duplicate.id)
        #expect(viewModel.quotes.first?.status == .draft)
        #expect(viewModel.quotes.first?.number == "P-2026-0002")
        #expect(viewModel.highlightedQuoteID == duplicate.id)
        #expect(viewModel.duplicateNoticeNumber == duplicate.number)
        #expect(viewModel.hapticEventCount == 1)
    }

    @Test("Cancelling a requested deletion leaves all quotes untouched")
    func cancelDeleteDoesNotDelete() {
        let first = makeListQuote(number: "P-2026-0001", date: Date(timeIntervalSince1970: 1_700_000_000))
        let second = makeListQuote(number: "P-2026-0002", date: Date(timeIntervalSince1970: 1_700_000_001))
        let quotes = FakeListQuotes(quotes: [first, second])
        let deleteUseCase = FakeDeleteQuote()
        let viewModel = makeViewModel(quotes: quotes, delete: deleteUseCase)
        viewModel.load()

        viewModel.requestDelete(first)
        #expect(viewModel.quotePendingDelete?.id == first.id)
        viewModel.cancelDelete()

        #expect(viewModel.quotePendingDelete == nil)
        #expect(deleteUseCase.deletedIDs.isEmpty)
        #expect(Set(viewModel.quotes.map(\.id)) == Set([first.id, second.id]))
    }

    @Test("Confirming deletion removes only the requested quote")
    func confirmDeleteRemovesOnlySelectedQuote() {
        let first = makeListQuote(number: "P-2026-0001", date: Date(timeIntervalSince1970: 1_700_000_000))
        let second = makeListQuote(number: "P-2026-0002", date: Date(timeIntervalSince1970: 1_700_000_001))
        let quotes = FakeListQuotes(quotes: [first, second])
        let deleteUseCase = FakeDeleteQuote()
        let viewModel = makeViewModel(quotes: quotes, delete: deleteUseCase)
        viewModel.load()

        viewModel.requestDelete(first)
        viewModel.confirmDelete()

        #expect(deleteUseCase.deletedIDs == [first.id])
        #expect(viewModel.quotes.map(\.id) == [second.id])
        #expect(viewModel.quotePendingDelete == nil)
        #expect(viewModel.state == .loaded)
    }

    @Test("A deletion error is exposed as a localized message key")
    func deleteErrorIsExposed() {
        let quote = makeListQuote(number: "P-2026-0001", date: Date(timeIntervalSince1970: 1_700_000_000))
        let quotes = FakeListQuotes(quotes: [quote])
        let deleteUseCase = FakeDeleteQuote(error: DomainError.quoteNotFound)
        let viewModel = makeViewModel(quotes: quotes, delete: deleteUseCase)
        viewModel.load()

        viewModel.requestDelete(quote)
        viewModel.confirmDelete()

        #expect(viewModel.state == .failed("error.quoteNotFound"))
        #expect(viewModel.quotes.map(\.id) == [quote.id])
    }

    private func makeViewModel(
        quotes: FakeListQuotes,
        duplicate: FakeDuplicateQuote? = nil,
        delete: FakeDeleteQuote = FakeDeleteQuote()
    ) -> QuoteListViewModel {
        let profile = MemoryProfileRepository()
        profile.profile = BusinessProfile(name: "Taller", numberPrefix: "P")
        let clock = FixedClock(date: Date(timeIntervalSince1970: 1_771_372_800))
        return QuoteListViewModel(
            listQuotes: quotes,
            createQuote: FakeCreateQuote(),
            duplicateQuote: duplicate ?? FakeDuplicateQuote(quotes: quotes, result: makeListQuote(number: "P-2026-0003", date: clock.now())),
            deleteQuote: delete
        )
    }

    private func makeListQuote(
        number: String,
        date: Date,
        status: QuoteStatus = .draft
    ) -> Quote {
        Quote(
            number: number,
            date: date,
            validityDays: 30,
            client: Client(name: "Client"),
            status: status,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
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

private final class FakeListQuotes: ListQuotesExecuting {
    var quotes: [Quote]

    init(quotes: [Quote]) {
        self.quotes = quotes
    }

    func execute() throws -> [Quote] {
        quotes.sorted { $0.date > $1.date }
    }
}

private struct FakeCreateQuote: CreateQuoteExecuting {
    func execute(client: Client) throws -> Quote {
        Quote(
            number: "P-2026-0009",
            date: Date(),
            validityDays: 30,
            client: client,
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
    }
}

private final class FakeDuplicateQuote: DuplicateQuoteExecuting {
    private let quotes: FakeListQuotes
    private let result: Quote
    var error: Error?

    init(quotes: FakeListQuotes, result: Quote, error: Error? = nil) {
        self.quotes = quotes
        self.result = result
        self.error = error
    }

    func execute(_ quote: Quote) throws -> Quote {
        if let error { throw error }
        quotes.quotes.append(result)
        return result
    }
}

private final class FakeDeleteQuote: DeleteQuoteExecuting {
    private(set) var deletedIDs: [UUID] = []
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func execute(id: Quote.ID) throws {
        if let error { throw error }
        deletedIDs.append(id)
    }
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
