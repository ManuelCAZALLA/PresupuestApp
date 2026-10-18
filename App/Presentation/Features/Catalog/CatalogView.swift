import SwiftUI
import QuoteCore

/// S7 Catálogo: búsqueda, lista por categorías y editor de partidas.
struct CatalogView: View {
    @Bindable var viewModel: CatalogViewModel
    @Environment(AppRouter.self) private var router

    @State private var editorTarget: EditorTarget?

    /// Qué está editando la hoja: una partida nueva o una existente.
    private enum EditorTarget: Identifiable {
        case new
        case edit(Item)

        var id: String {
            switch self {
            case .new:
                return "new"
            case .edit(let item):
                return "edit-\(item.id)"
            }
        }
    }

    private var isEmptyCatalog: Bool {
        viewModel.state == .loaded && viewModel.items.isEmpty
    }

    var body: some View {
        List {
            ForEach(viewModel.sections, id: \.category) { section in
                Section(section.category) {
                    ForEach(section.items) { item in
                        row(for: item)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "catalog.search")
        .navigationTitle("catalog.title")
        .toolbar { addToolbar }
        .sheet(item: $editorTarget) { target in
            editor(for: target)
        }
        .task {
            viewModel.load()
        }
        .overlay { emptyOverlay }
    }

    // MARK: - Partes de la vista

    private func row(for item: Item) -> some View {
        ItemRow(
            item: item,
            onEdit: { editorTarget = .edit(item) },
            onDelete: { viewModel.deleteItem(item) }
        )
    }

    @ToolbarContentBuilder
    private var addToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                editorTarget = .new
            } label: {
                Label("catalog.addItem", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private func editor(for target: EditorTarget) -> some View {
        switch target {
        case .new:
            ItemEditorView { created in
                viewModel.saveItem(created, isNew: true)
            }
        case .edit(let item):
            ItemEditorView(item: item) { updated in
                viewModel.saveItem(updated, isNew: false)
            }
        }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if isEmptyCatalog {
            ContentUnavailableView {
                Label("catalog.empty", systemImage: "tag")
            } description: {
                Text("catalog.empty.message")
            } actions: {
                Button {
                    router.push(.importTariff)
                } label: {
                    Label("catalog.empty.import", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    router.push(.importTariff)
                } label: {
                    Label("catalog.empty.paste", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.bordered)

                Button {
                    editorTarget = .new
                } label: {
                    Label("catalog.empty.addManual", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Fila

private struct ItemRow: View {
    let item: Item
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var hasPrice: Bool {
        item.unitPrice > Decimal.zero
    }
    
    var body: some View {
        HStack {
            nameAndUnit
            Spacer()
            priceLabel
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("action.delete", systemImage: "trash")
            }
        }
    }
    
    private var nameAndUnit: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
        }
    }
    
    @ViewBuilder
    private var priceLabel: some View {
        if hasPrice {
            Text(item.unitPrice, format: .currency(code: "EUR")) // O la moneda que utilices
                .foregroundColor(.secondary)
        }
    }
}
