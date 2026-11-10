import SwiftUI
import QuoteCore

/// Editor de agrupación: nombre y partidas (cada una de una partida del catálogo + cantidad).
struct KitEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var entries: [EditableEntry]
    @State private var isPickingItem = false

    private let kit: Kit?
    private let catalogItems: [Item]
    private let onSave: (Kit) -> Void

    struct EditableEntry: Identifiable, Equatable {
        let id: UUID
        var itemID: UUID
        var itemName: String
        var quantity: String

        init(item: Item, quantity: Decimal = 1) {
            self.id = UUID()
            self.itemID = item.id
            self.itemName = item.name
            self.quantity = CurrencyFormatter.plainString(from: quantity)
        }

        init(entry: KitEntry, itemName: String) {
            self.id = UUID()
            self.itemID = entry.itemID
            self.itemName = itemName
            self.quantity = CurrencyFormatter.plainString(from: entry.quantity)
        }
    }

    init(
        kit: Kit? = nil,
        catalogItems: [Item],
        itemsByID: [UUID: Item],
        onSave: @escaping (Kit) -> Void
    ) {
        self.kit = kit
        self.catalogItems = catalogItems
        self.onSave = onSave
        _name = State(initialValue: kit?.name ?? "")
        _entries = State(initialValue: kit?.entries.map { entry in
            EditableEntry(entry: entry, itemName: itemsByID[entry.itemID]?.name ?? "—")
        } ?? [])
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !entries.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("kits.name", text: $name)
            }
            Section("kits.entries") {
                if entries.isEmpty {
                    Text("kits.noEntries")
                        .foregroundStyle(.secondary)
                }
                ForEach($entries) { $entry in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(entry.itemName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("kits.entry.quantity", text: $entry.quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                    }
                }
                .onDelete { entries.remove(atOffsets: $0) }

                Button {
                    isPickingItem = true
                } label: {
                    Label("kits.addEntry", systemImage: "plus")
                }
                .disabled(catalogItems.isEmpty)
            }
        }
        .navigationTitle(kit == nil ? "kits.add" : "kits.edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { save() }
                    .disabled(!canSave)
            }
        }
        .sheet(isPresented: $isPickingItem) {
            NavigationStack {
                if catalogItems.isEmpty {
                    ContentUnavailableView(
                        "kits.picker.catalog.empty",
                        systemImage: "tag",
                        description: Text("kits.picker.catalog.empty.message")
                    )
                } else {
                    List(catalogItems) { item in
                        Button {
                            entries.append(EditableEntry(item: item))
                            isPickingItem = false
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Text(LocalizedStringKey(DomainLabels.measureUnit(item.unit)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .navigationTitle("kits.picker.item")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("action.cancel") { isPickingItem = false }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let domainEntries = entries.compactMap { entry -> KitEntry? in
            let qty = Decimal(string: entry.quantity.replacingOccurrences(of: ",", with: ".")) ?? Decimal(1)
            guard qty > 0 else { return nil }
            return KitEntry(itemID: entry.itemID, quantity: qty)
        }
        guard !trimmed.isEmpty, !domainEntries.isEmpty else { return }
        onSave(Kit(id: kit?.id ?? UUID(), name: trimmed, entries: domainEntries))
        dismiss()
    }
}
