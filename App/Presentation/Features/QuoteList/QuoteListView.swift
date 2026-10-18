import SwiftUI
import QuoteCore

/// S2 Lista de presupuestos: búsqueda, estados y botón grande de alta.
struct QuoteListView: View {
    @Bindable var viewModel: QuoteListViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            ForEach(viewModel.filteredQuotes) { quote in
                Button {
                    router.openQuote(quote.id)
                } label: {
                    QuoteRow(
                        quote: quote,
                        total: viewModel.totals(for: quote).total
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        viewModel.duplicate(quote)
                    } label: {
                        Label("quote.list.duplicate", systemImage: "plus.square.on.square")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay { emptyOverlay }
        .searchable(text: $viewModel.searchText, prompt: "quote.list.search")
        .navigationTitle("quote.list.title")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            Button {
                if let created = viewModel.create() {
                    router.openQuote(created.id)
                }
            } label: {
                Label("quote.list.new", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
            .accessibilityLabel("quote.list.new")
        }
        .task { viewModel.load() }
        .onChange(of: router.quotesPath.count) { _, _ in
            viewModel.load()
        }
        .alert(
            "error.title",
            isPresented: Binding(
                get: { if case .failed = viewModel.state { return true } else { return false } },
                set: { presented in
                    if !presented { viewModel.load() }
                }
            )
        ) {
            Button("action.ok", role: .cancel) {}
        } message: {
            if case .failed(let message) = viewModel.state {
                Text(LocalizedStringKey(message))
            }
        }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if viewModel.state == .loaded && viewModel.filteredQuotes.isEmpty {
            ContentUnavailableView {
                Label("quote.list.empty", systemImage: "doc.text")
            } description: {
                Text(
                    viewModel.searchText.isEmpty
                        ? "quote.list.empty.message"
                        : "quote.list.empty.search"
                )
            }
        }
    }
}

private struct QuoteRow: View {
    let quote: Quote
    let total: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if quote.client.name.isEmpty {
                        Text("quote.client.placeholder")
                    } else {
                        Text(quote.client.name)
                    }
                }
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                Spacer()
                Text(CurrencyFormatter.string(from: total))
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
            }
            HStack(spacing: 8) {
                Text(verbatim: quote.number)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                StatusBadge(status: quote.status)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
