import Foundation
import Observation
import QuoteCore

/// Cliente agrupado a partir de sus presupuestos. No hay entidad `Client`
/// propia en la v1: el directorio se deriva de los datos guardados en cada
/// presupuesto, así que editar uno antiguo no reescribe los demás (D-021).
struct ClientGroup: Identifiable {
    let id: String
    let client: Client
    let quotes: [Quote]

    var quoteCount: Int { quotes.count }
    var lastDate: Date { quotes.first?.date ?? .distantPast }
}

/// Vista modelo de la pestaña Clientes: agrupa, busca y crea presupuestos
/// reutilizando los datos del cliente.
@MainActor
@Observable
final class ClientsViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var groups: [ClientGroup] = []
    private(set) var actionError: String?
    var searchText = ""

    private let listQuotes: any ListQuotesExecuting
    private let createQuote: any CreateQuoteExecuting
    private let calculator = QuoteCalculator()

    init(
        listQuotes: any ListQuotesExecuting,
        createQuote: any CreateQuoteExecuting
    ) {
        self.listQuotes = listQuotes
        self.createQuote = createQuote
    }

    var filteredGroups: [ClientGroup] {
        let query = Self.normalize(searchText)
        guard !query.isEmpty else { return groups }
        return groups.filter { group in
            Self.normalize(group.client.name).contains(query)
                || Self.normalize(group.client.phone).contains(query)
        }
    }

    func load() {
        state = .loading
        do {
            groups = Self.grouped(quotes: try listQuotes.execute())
            state = .loaded
        } catch {
            groups = []
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func totals(for quote: Quote) -> QuoteTotals {
        calculator.calculate(lines: quote.lines, discount: quote.discount)
    }

    func createQuote(for group: ClientGroup) -> Quote? {
        do {
            return try createQuote.execute(client: group.client)
        } catch {
            actionError = AppErrorMapper.message(for: error)
            return nil
        }
    }

    func clearActionError() {
        actionError = nil
    }

    /// Agrupa por nombre normalizado. Los presupuestos sin nombre de cliente
    /// se quedan fuera del directorio (siguen visibles en Presupuestos).
    static func grouped(quotes: [Quote]) -> [ClientGroup] {
        var order: [String] = []
        var buckets: [String: [Quote]] = [:]
        var clients: [String: Client] = [:]

        for quote in quotes.sorted(by: { $0.date > $1.date }) {
            let name = quote.client.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let key = Self.normalize(name)
            if buckets[key] == nil {
                order.append(key)
                clients[key] = quote.client
            }
            buckets[key, default: []].append(quote)
        }

        return order.compactMap { key in
            guard let quotes = buckets[key], let client = clients[key] else { return nil }
            return ClientGroup(id: key, client: client, quotes: quotes)
        }
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
