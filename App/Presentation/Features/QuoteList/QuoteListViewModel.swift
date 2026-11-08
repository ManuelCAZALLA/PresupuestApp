import Foundation
import Observation
import QuoteCore

protocol ListQuotesExecuting {
    func execute() throws -> [Quote]
}

protocol CreateQuoteExecuting {
    func execute(client: Client) throws -> Quote
}

protocol DuplicateQuoteExecuting {
    func execute(_ quote: Quote) throws -> Quote
}

protocol DeleteQuoteExecuting {
    func execute(id: Quote.ID) throws
}

extension ListQuotes: ListQuotesExecuting {}
extension CreateQuote: CreateQuoteExecuting {}
extension DuplicateQuote: DuplicateQuoteExecuting {}
extension DeleteQuote: DeleteQuoteExecuting {}

/// Vista modelo de S2 (QuoteList): lista, búsqueda, alta y duplicado.
@MainActor
@Observable
final class QuoteListViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var quotes: [Quote] = []
    private(set) var quotePendingDelete: Quote?
    private(set) var highlightedQuoteID: Quote.ID?
    private(set) var duplicateNoticeNumber: String?
    private(set) var hapticEventCount = 0
    var searchText = ""

    private let listQuotes: any ListQuotesExecuting
    private let createQuote: any CreateQuoteExecuting
    private let duplicateQuote: any DuplicateQuoteExecuting
    private let deleteQuote: any DeleteQuoteExecuting
    private let calculator = QuoteCalculator()

    init(
        listQuotes: any ListQuotesExecuting,
        createQuote: any CreateQuoteExecuting,
        duplicateQuote: any DuplicateQuoteExecuting,
        deleteQuote: any DeleteQuoteExecuting
    ) {
        self.listQuotes = listQuotes
        self.createQuote = createQuote
        self.duplicateQuote = duplicateQuote
        self.deleteQuote = deleteQuote
    }

    var filteredQuotes: [Quote] {
        guard !searchText.isEmpty else { return quotes }
        return quotes.filter { quote in
            quote.number.localizedCaseInsensitiveContains(searchText)
                || quote.client.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    func totals(for quote: Quote) -> QuoteTotals {
        calculator.calculate(lines: quote.lines, discount: quote.discount)
    }

    func load() {
        state = .loading
        do {
            quotes = try listQuotes.execute()
            state = .loaded
        } catch {
            quotes = []
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func create() -> Quote? {
        do {
            let quote = try createQuote.execute(client: Client())
            load()
            return quote
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
            return nil
        }
    }

    func duplicate(_ quote: Quote) {
        do {
            let duplicate = try duplicateQuote.execute(quote)
            quotes.removeAll { $0.id == duplicate.id }
            quotes.insert(duplicate, at: 0)
            highlightedQuoteID = duplicate.id
            duplicateNoticeNumber = duplicate.number
            hapticEventCount += 1
            state = .loaded
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func requestDelete(_ quote: Quote) {
        quotePendingDelete = quote
    }

    func confirmDelete() {
        guard let quote = quotePendingDelete else { return }
        do {
            try deleteQuote.execute(id: quote.id)
            quotePendingDelete = nil
            quotes.removeAll { $0.id == quote.id }
            state = .loaded
        } catch {
            quotePendingDelete = nil
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func cancelDelete() {
        quotePendingDelete = nil
    }

    func clearDuplicateFeedback() {
        highlightedQuoteID = nil
        duplicateNoticeNumber = nil
    }
}
