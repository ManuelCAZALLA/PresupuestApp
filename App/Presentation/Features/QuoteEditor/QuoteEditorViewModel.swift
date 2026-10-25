import Foundation
import Observation
import QuoteCore

/// Vista modelo de S5 (presupuesto a mano): cliente, líneas, descuento y total.
@MainActor
@Observable
final class QuoteEditorViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum DiscountKind: String, CaseIterable, Identifiable {
        case none
        case percent
        case amount
        var id: String { rawValue }
    }

    let quoteID: UUID

    private(set) var state: ViewState = .idle
    private(set) var quote: Quote?
    private(set) var totals: QuoteTotals?
    private(set) var catalog: [Item] = []

    var clientName = ""
    var clientPhone = ""
    var clientAddress = ""
    var workAddress = ""
    var notes = ""
    var discountKind: DiscountKind = .none
    var discountValue = ""
    var itemSearch = ""

    private let loadQuote: LoadQuote
    private let updateQuote: UpdateQuote
    private let addLine: AddLine
    private let updateLineQuantity: UpdateLineQuantity
    private let removeLine: RemoveLine
    private let listItems: ListItems
    private let calculator = QuoteCalculator()

    init(
        quoteID: UUID,
        loadQuote: LoadQuote,
        updateQuote: UpdateQuote,
        addLine: AddLine,
        updateLineQuantity: UpdateLineQuantity,
        removeLine: RemoveLine,
        listItems: ListItems
    ) {
        self.quoteID = quoteID
        self.loadQuote = loadQuote
        self.updateQuote = updateQuote
        self.addLine = addLine
        self.updateLineQuantity = updateLineQuantity
        self.removeLine = removeLine
        self.listItems = listItems
    }

    var filteredCatalog: [Item] {
        guard !itemSearch.isEmpty else { return catalog }
        return catalog.filter { item in
            item.name.localizedCaseInsensitiveContains(itemSearch)
                || item.aliases.contains { $0.localizedCaseInsensitiveContains(itemSearch) }
        }
    }

    func lineTotal(_ line: QuoteLine) -> Decimal {
        calculator.lineTotal(line)
    }

    func load() {
        state = .loading
        do {
            let loaded = try loadQuote.execute(id: quoteID)
            quote = loaded
            catalog = try listItems.execute()
            hydrate(from: loaded)
            totals = calculator.calculate(lines: loaded.lines, discount: loaded.discount)
            state = .loaded
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func persistDetails() {
        guard var quote else { return }
        quote.client = Client(
            name: clientName,
            phone: clientPhone,
            address: clientAddress,
            workAddress: workAddress.isEmpty ? nil : workAddress
        )
        quote.notes = notes
        quote.discount = parsedDiscount()
        do {
            try updateQuote.execute(quote)
            refreshQuote(hydrateFields: false)
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func addItem(_ item: Item) {
        persistDetails()
        do {
            try addLine.execute(itemID: item.id, quantity: Decimal(1), in: quoteID)
            refreshQuote(hydrateFields: false)
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func increase(_ line: QuoteLine) {
        changeQuantity(line, by: Decimal(1))
    }

    func decrease(_ line: QuoteLine) {
        guard line.quantity > 1 else { return }
        changeQuantity(line, by: Decimal(-1))
    }

    func delete(_ line: QuoteLine) {
        do {
            try removeLine.execute(quoteID: quoteID, lineID: line.id)
            refreshQuote(hydrateFields: false)
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    private func changeQuantity(_ line: QuoteLine, by delta: Decimal) {
        do {
            try updateLineQuantity.execute(
                quoteID: quoteID,
                lineID: line.id,
                quantity: line.quantity + delta
            )
            refreshQuote(hydrateFields: false)
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    private func refreshQuote(hydrateFields: Bool) {
        do {
            let loaded = try loadQuote.execute(id: quoteID)
            quote = loaded
            if hydrateFields {
                hydrate(from: loaded)
            }
            totals = calculator.calculate(lines: loaded.lines, discount: loaded.discount)
            state = .loaded
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    private func hydrate(from quote: Quote) {
        clientName = quote.client.name
        clientPhone = quote.client.phone
        clientAddress = quote.client.address
        workAddress = quote.client.workAddress ?? ""
        notes = quote.notes
        switch quote.discount {
        case .none:
            discountKind = .none
            discountValue = ""
        case .percent(let value):
            discountKind = .percent
            discountValue = CurrencyFormatter.plainString(from: value)
        case .amount(let value):
            discountKind = .amount
            discountValue = CurrencyFormatter.plainString(from: value)
        }
    }

    private func parsedDiscount() -> Discount {
        let value = Decimal(string: discountValue.replacingOccurrences(of: ",", with: ".")) ?? Decimal(0)
        switch discountKind {
        case .none:
            return .none
        case .percent:
            return .percent(value)
        case .amount:
            return .amount(value)
        }
    }
}
