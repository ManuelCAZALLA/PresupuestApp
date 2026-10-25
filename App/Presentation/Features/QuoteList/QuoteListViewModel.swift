import Foundation
import Observation
import QuoteCore

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
    var searchText = ""

    private let listQuotes: ListQuotes
    private let createQuote: CreateQuote
    private let duplicateQuote: DuplicateQuote
    private let calculator = QuoteCalculator()

    init(
        listQuotes: ListQuotes,
        createQuote: CreateQuote,
        duplicateQuote: DuplicateQuote
    ) {
        self.listQuotes = listQuotes
        self.createQuote = createQuote
        self.duplicateQuote = duplicateQuote
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
            _ = try duplicateQuote.execute(quote)
            load()
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }
}
