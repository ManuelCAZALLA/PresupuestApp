import Foundation

/// Lista los presupuestos, del más reciente al más antiguo.
public final class ListQuotes {
    private let quotes: QuoteRepository

    public init(quotes: QuoteRepository) {
        self.quotes = quotes
    }

    public func execute() throws -> [Quote] {
        try quotes.all().sorted { $0.date > $1.date }
    }
}
