import Foundation
import QuoteCore
import Testing
@testable import PresupuestApp

@Suite("Clientes")
@MainActor
struct ClientsViewModelTests {
    @Test("Agrupa por nombre, ignora los que no tienen nombre y ordena por el más reciente")
    func groupsAndSorts() throws {
        let viewModel = makeViewModel(quotes: sampleQuotes())
        viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.groups.map(\.client.name) == ["Luis", "ANA"])
        #expect(viewModel.groups.allSatisfy { !$0.client.name.isEmpty })

        let ana = try #require(viewModel.groups.first { $0.client.name == "ANA" })
        #expect(ana.quoteCount == 2)
        // El teléfono sale del presupuesto más reciente del cliente.
        #expect(ana.client.phone == "600222")
    }

    @Test("La búsqueda filtra por nombre y por teléfono")
    func searchFilters() {
        let viewModel = makeViewModel(quotes: sampleQuotes())
        viewModel.load()

        viewModel.searchText = "ana"
        #expect(viewModel.filteredGroups.map(\.client.name) == ["ANA"])

        viewModel.searchText = "6001"
        #expect(viewModel.filteredGroups.map(\.client.name) == ["Luis"])

        viewModel.searchText = "maria"
        #expect(viewModel.filteredGroups.isEmpty)
    }

    @Test("Crear un presupuesto reutiliza los datos del cliente")
    func createsWithClient() throws {
        let spy = SpyCreateQuote(
            result: makeQuote(name: "Nuevo", date: 900)
        )
        let viewModel = ClientsViewModel(
            listQuotes: StubListQuotes(quotes: sampleQuotes()),
            createQuote: spy
        )
        viewModel.load()
        let group = try #require(viewModel.groups.first)

        let created = viewModel.createQuote(for: group)

        #expect(spy.receivedClients == [group.client])
        #expect(created?.client == group.client)
        #expect(viewModel.actionError == nil)
    }

    @Test("Un error al crear el presupuesto se expone como clave localizada")
    func createErrorIsExposed() throws {
        let spy = SpyCreateQuote(
            result: makeQuote(name: "Nuevo", date: 900),
            error: DomainError.quotaExceeded
        )
        let viewModel = ClientsViewModel(
            listQuotes: StubListQuotes(quotes: sampleQuotes()),
            createQuote: spy
        )
        viewModel.load()
        let group = try #require(viewModel.groups.first)

        #expect(viewModel.createQuote(for: group) == nil)
        #expect(viewModel.actionError == "error.quotaExceeded")

        viewModel.clearActionError()
        #expect(viewModel.actionError == nil)
    }

    private func makeViewModel(quotes: [Quote]) -> ClientsViewModel {
        ClientsViewModel(
            listQuotes: StubListQuotes(quotes: quotes),
            createQuote: SpyCreateQuote(result: makeQuote(name: "Nuevo", date: 900))
        )
    }

    private func sampleQuotes() -> [Quote] {
        [
            makeQuote(name: "Ana", date: 100),
            makeQuote(name: "Luis", phone: "600111", date: 300),
            makeQuote(name: "ANA", phone: "600222", date: 200),
            makeQuote(name: "", date: 400)
        ]
    }

    private func makeQuote(
        name: String,
        phone: String = "",
        date: TimeInterval
    ) -> Quote {
        Quote(
            number: "P-2026-\(Int(date))",
            date: Date(timeIntervalSince1970: date),
            validityDays: 30,
            client: Client(name: name, phone: phone),
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: Decimal(21)
        )
    }
}

private struct StubListQuotes: ListQuotesExecuting {
    let quotes: [Quote]

    func execute() throws -> [Quote] {
        quotes
    }
}

private final class SpyCreateQuote: CreateQuoteExecuting {
    private(set) var receivedClients: [Client] = []
    private let result: Quote
    private let error: Error?

    init(result: Quote, error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func execute(client: Client) throws -> Quote {
        if let error { throw error }
        receivedClients.append(client)
        var quote = result
        quote.client = client
        return quote
    }
}
