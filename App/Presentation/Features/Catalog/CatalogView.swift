import SwiftUI
import QuoteCore

/// S7 Catálogo (pestaña Precios): búsqueda, lista por categorías y editor.
struct CatalogView: View {
    @Bindable var viewModel: CatalogViewModel
    @Environment(AppRouter.self) private var router

    @State private var editingItem: Item?

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
                            onEdit: { editingItem = item },
                            onDelete: { viewModel.deleteItem(item) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } header: {
                    Group {
                        if let category = section.category {
                            Text(category)
                        } else {
                            Text("category.uncategorized")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandPalette.accent)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BrandPalette.background)
        .readableContentWidth(780)
        .searchable(text: $viewModel.searchText, prompt: "catalog.search")
        .navigationTitle("catalog.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.presentNewItem()
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
        .sheet(item: $editingItem) { item in
            NavigationStack {
                ItemEditorView(item: item) { updated in
                    viewModel.saveItem(updated, isNew: false)
                }
            }
            .adaptiveSheetDetents([.large])
        }
        .task { viewModel.load() }
        .onChange(of: router.isImportPresented) { _, presented in
            if !presented { viewModel.load() }
        }
        .onChange(of: router.isItemEditorPresented) { _, presented in
            if !presented { viewModel.load() }
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
                TariffStartActions(
                    onImport: { router.presentImport() },
                    onPaste: { router.presentImport() },
                    onAddManually: { router.presentNewItem() }
                )
                .frame(maxWidth: 420)
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
            CardSurface(padding: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandPalette.accent)
                        .frame(width: 38, height: 38)
                        .background(BrandPalette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(LocalizedStringKey(DomainLabels.measureUnit(item.unit)))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if item.unitPrice > 0 {
                        Text(CurrencyFormatter.string(from: item.unitPrice))
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("catalog.noPrice")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("action.delete", systemImage: "trash")
            }
        }
        .accessibilityHint("catalog.editItem")
    }
}
