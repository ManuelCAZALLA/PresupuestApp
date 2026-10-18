import Foundation
import Observation
import QuoteCore

/// Vista modelo de S7 (Catálogo): lista por categorías, búsqueda,
/// crea, edita y borra partidas.
@MainActor
@Observable
final class CatalogViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var items: [Item] = []
    var searchText = ""

    private let listItems: ListItems
    private let manageItems: ManageItems

    init(listItems: ListItems, manageItems: ManageItems) {
        self.listItems = listItems
        self.manageItems = manageItems
    }

    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText)
                || item.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// Partidas agrupadas por categoría, para la lista por secciones.
    var sections: [(category: String, items: [Item])] {
        let sorted = filteredItems.sorted { ($0.category ?? "") < ($1.category ?? "") }
        return Dictionary(grouping: sorted) { $0.category ?? "category.uncategorized" }
            .map { (category: $0.key, items: $0.value) }
            .sorted { $0.category < $1.category }
    }

    func load() {
        state = .loading
        do {
            items = try listItems.execute()
            state = .loaded
        } catch {
            items = []
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func saveItem(_ item: Item, isNew: Bool) {
        do {
            try manageItems.execute(isNew ? .create(item) : .update(item))
            load()
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func deleteItem(_ item: Item) {
        do {
            try manageItems.execute(.delete(item.id))
            load()
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }
}
