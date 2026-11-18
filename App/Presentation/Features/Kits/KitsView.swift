import SwiftUI
import QuoteCore

/// Apartado de agrupaciones: lista, alta, edición y borrado.
struct KitsView: View {
    @Bindable var viewModel: KitsViewModel
    @Environment(AppRouter.self) private var router
    @State private var isAdding = false
    @State private var editingKit: Kit?

    var body: some View {
        List {
            ForEach(viewModel.kits) { kit in
                Button {
                    editingKit = kit
                } label: {
                    CardSurface(padding: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandPalette.accent)
                                .frame(width: 38, height: 38)
                                .background(BrandPalette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(kit.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                let detail = viewModel.summary(for: kit)
                                if !detail.isEmpty {
                                    Text(detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.delete(kit)
                    } label: {
                        Label("action.delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BrandPalette.background)
        .readableContentWidth(780)
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
            .adaptiveSheetDetents([.large])
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
            .adaptiveSheetDetents([.large])
        }
        .task { viewModel.load() }
        .onChange(of: router.selectedTab) { _, tab in
            if tab == .kits { viewModel.load() }
        }
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
