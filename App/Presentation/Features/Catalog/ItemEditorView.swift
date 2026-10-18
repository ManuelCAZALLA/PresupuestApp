import SwiftUI
import QuoteCore

/// Editor de partida (crear o editar): nombre, unidad, tipo,
/// categoría, precio unitario, IVA opcional y sinónimos.
struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var unit: MeasureUnit = .unit
    @State private var kind: ItemKind = .material
    @State private var category = ""
    @State private var price = ""
    @State private var vatRate = ""
    @State private var aliases = ""

    private let item: Item?
    private let onSave: (Item) -> Void

    init(item: Item? = nil, onSave: @escaping (Item) -> Void) {
        self.item = item
        self.onSave = onSave
        if let item {
            _name = State(initialValue: item.name)
            _unit = State(initialValue: item.unit)
            _kind = State(initialValue: item.kind)
            _category = State(initialValue: item.category ?? "")
            _price = State(initialValue: CurrencyFormatter.plainString(from: item.unitPrice))
            _vatRate = State(initialValue: item.vatRate.map { CurrencyFormatter.plainString(from: $0) } ?? "")
            _aliases = State(initialValue: item.aliases.joined(separator: ", "))
        }
    }

    var body: some View {
        Form {
            Section {
                TextField("field.name", text: $name)
                Picker("field.unit", selection: $unit) {
                    Text("measure.unit").tag(MeasureUnit.unit)
                    Text("measure.meter").tag(MeasureUnit.meter)
                    Text("measure.squareMeter").tag(MeasureUnit.squareMeter)
                    Text("measure.cubicMeter").tag(MeasureUnit.cubicMeter)
                    Text("measure.hour").tag(MeasureUnit.hour)
                    Text("measure.lumpSum").tag(MeasureUnit.lumpSum)
                }
                Picker("field.kind", selection: $kind) {
                    Text("kind.material").tag(ItemKind.material)
                    Text("kind.labor").tag(ItemKind.labor)
                    Text("kind.travel").tag(ItemKind.travel)
                    Text("kind.other").tag(ItemKind.other)
                }
                TextField("field.category", text: $category)
                TextField("field.price", text: $price)
                    .keyboardType(.decimalPad)
                TextField("field.itemVAT", text: $vatRate)
                    .keyboardType(.decimalPad)
                TextField("field.aliases", text: $aliases)
            } footer: {
                Text("field.itemVAT.footer")
            }
        }
        .navigationTitle(item == nil ? "catalog.addItem" : "catalog.editItem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAliases = aliases
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let priceDecimal = Decimal(
            string: price.replacingOccurrences(of: ",", with: ".")
        ) ?? Decimal(0)
        let vat = Decimal(string: vatRate.replacingOccurrences(of: ",", with: "."))
        onSave(
            Item(
                id: item?.id ?? UUID(),
                name: trimmed,
                aliases: parsedAliases,
                unit: unit,
                unitPrice: priceDecimal,
                vatRate: vatRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : vat,
                kind: kind,
                category: category.isEmpty ? nil : category,
                trade: item?.trade ?? .other
            )
        )
        dismiss()
    }
}
