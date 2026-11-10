import Foundation
import Observation
import QuoteCore

/// Vista modelo del apartado de agrupaciones: lista, crea, edita y borra kits.
@MainActor
@Observable
final class KitsViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var kits: [Kit] = []
    private(set) var itemsByID: [UUID: Item] = [:]

    private let listKits: ListKits
    private let manageKits: ManageKits
    private let listItems: ListItems

    init(listKits: ListKits, manageKits: ManageKits, listItems: ListItems) {
        self.listKits = listKits
        self.manageKits = manageKits
        self.listItems = listItems
    }

    var catalogItems: [Item] {
        itemsByID.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func itemName(for id: UUID) -> String {
        itemsByID[id]?.name ?? "—"
    }

    func summary(for kit: Kit) -> String {
        kit.entries.map { entry in
            let name = itemName(for: entry.itemID)
            let qty = CurrencyFormatter.plainString(from: entry.quantity)
            return "\(name) × \(qty)"
        }.joined(separator: ", ")
    }

    func load() {
        state = .loading
        do {
            let items = try listItems.execute()
            itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            kits = try listKits.execute().sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            state = .loaded
        } catch {
            kits = []
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func save(_ kit: Kit, isNew: Bool) {
        do {
            try manageKits.execute(isNew ? .create(kit) : .update(kit))
            load()
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func delete(_ kit: Kit) {
        do {
            try manageKits.execute(.delete(kit.id))
            load()
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }
}
