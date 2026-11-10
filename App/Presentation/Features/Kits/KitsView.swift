import SwiftUI
import QuoteCore

/// Apartado de agrupaciones: lista, alta, edición y borrado.
struct KitsView: View {
    @Bindable var viewModel: KitsViewModel
    @State private var isAdding = false
    @State private var editingKit: Kit?

    var body: some View {
        List {
            ForEach(viewModel.kits) { kit in
                Button {
                    editingKit = kit
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kit.name)
                            .foregroundStyle(.primary)
                        let detail = viewModel.summary(for: kit)
                        if !detail.isEmpty {
                            Text(detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.delete(kit)
                    } label: {
                        Label("action.delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("kits.title")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAdding = true
                } label: {
                    Label("kits.add", systemImage: "plus")
                }
            }
        }
        .overlay {
            if viewModel.state == .loaded && viewModel.kits.isEmpty {
                ContentUnavailableView {
                    Label("kits.empty", systemImage: "square.stack.3d.up")
                } description: {
                    Text("kits.empty.message")
                } actions: {
                    Button("kits.add") { isAdding = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $isAdding) {
            NavigationStack {
                KitEditorView(
                    catalogItems: viewModel.catalogItems,
                    itemsByID: viewModel.itemsByID
                ) { kit in
                    viewModel.save(kit, isNew: true)
                }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $editingKit) { kit in
            NavigationStack {
                KitEditorView(
                    kit: kit,
                    catalogItems: viewModel.catalogItems,
                    itemsByID: viewModel.itemsByID
                ) { updated in
                    viewModel.save(updated, isNew: false)
                }
            }
            .presentationDetents([.large])
        }
        .task { viewModel.load() }
        .alert(
            "error.title",
            isPresented: Binding(
                get: { if case .failed = viewModel.state { return true } else { return false } },
                set: { _ in }
            )
        ) {
            Button("action.ok", role: .cancel) {}
        } message: {
            if case .failed(let message) = viewModel.state {
                Text(LocalizedStringKey(message))
            }
        }
    }
}
