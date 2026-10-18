import SwiftUI
import QuoteCore

/// S7 Catálogo (pestaña Precios): búsqueda, lista por categorías y editor.
struct CatalogView: View {
    @Bindable var viewModel: CatalogViewModel
    @Environment(AppRouter.self) private var router

    @State private var editorTarget: EditorTarget?

    private enum EditorTarget: Identifiable {
        case new
        case edit(Item)

        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let item): return "edit-\(item.id)"
            }
        }
    }

    private var isEmptyCatalog: Bool {
        viewModel.state == .loaded && viewModel.items.isEmpty && viewModel.searchText.isEmpty
    }

    var body: some View {
        List {
            ForEach(viewModel.sections, id: \.category) { section in
                Section {
                    ForEach(section.items) { item in
                        ItemRow(
                            item: item,
                            onEdit: { editorTarget = .edit(item) },
                            onDelete: { viewModel.deleteItem(item) }
                        )
                    }
                } header: {
                    Text(LocalizedStringKey(section.category))
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "catalog.search")
        .navigationTitle("catalog.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorTarget = .new
                } label: {
                    Label("catalog.addItem", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.presentImport()
                } label: {
                    Label("catalog.import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .overlay { emptyOverlay }
        .sheet(item: $editorTarget) { target in
            NavigationStack {
                editor(for: target)
            }
            .presentationDetents([.large])
        }
        .task { viewModel.load() }
        .onChange(of: router.isImportPresented) { _, presented in
            if !presented { viewModel.load() }
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
                    router.presentImport()
                } label: {
                    Label("catalog.empty.import", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    router.presentImport()
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
            .padding(.horizontal, 24)
        }
    }
}

private struct ItemRow: View {
    let item: Item
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey(DomainLabels.measureUnit(item.unit)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if item.unitPrice > 0 {
                    Text(CurrencyFormatter.string(from: item.unitPrice))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("catalog.noPrice")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("action.delete", systemImage: "trash")
            }
        }
        .accessibilityHint("catalog.editItem")
    }
}
