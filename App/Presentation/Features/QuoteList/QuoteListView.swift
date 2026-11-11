import Foundation
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
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        viewModel.duplicate(quote)
                    } label: {
                        Label("quote.list.duplicate", systemImage: "plus.square.on.square")
                    }
                    .tint(duplicateTint)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.requestDelete(quote)
                    } label: {
                        Label("quote.list.delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        viewModel.duplicate(quote)
                    } label: {
                        Label("quote.list.duplicate", systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive) {
                        viewModel.requestDelete(quote)
                    } label: {
                        Label("quote.list.delete", systemImage: "trash")
                    }
                }
                .accessibilityAction(named: Text("quote.list.duplicate")) {
                    viewModel.duplicate(quote)
                }
                .accessibilityAction(named: Text("quote.list.delete")) {
                    viewModel.requestDelete(quote)
                }
                .listRowBackground(
                    viewModel.highlightedQuoteID == quote.id
                        ? duplicateTint.opacity(0.14)
                        : Color.clear
                )
                .animation(.easeInOut(duration: 0.2), value: viewModel.highlightedQuoteID)
            }
        }
        .listStyle(.insetGrouped)
        .overlay { emptyOverlay }
        .overlay(alignment: .top) {
            if let number = viewModel.duplicateNoticeNumber {
                Text(duplicateNotice(for: number))
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().stroke(duplicateTint.opacity(0.3)))
                    .shadow(radius: 4, y: 2)
                    .padding(.top, 8)
                    .accessibilityAddTraits(.updatesFrequently)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.duplicateNoticeNumber)
        .sensoryFeedback(.success, trigger: viewModel.hapticEventCount)
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
        .task(id: viewModel.duplicateNoticeNumber) {
            guard viewModel.duplicateNoticeNumber != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            viewModel.clearDuplicateFeedback()
        }
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
        .confirmationDialog(
            "quote.list.delete.title",
            isPresented: Binding(
                get: { viewModel.quotePendingDelete != nil },
                set: { if !$0 { viewModel.cancelDelete() } }
            ),
            titleVisibility: .visible
        ) {
            Button("quote.list.delete", role: .destructive) {
                viewModel.confirmDelete()
            }
            Button("action.cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            if let quote = viewModel.quotePendingDelete {
                Text(deleteConfirmation(for: quote))
            }
        }
    }

    private var duplicateTint: Color {
        Color(red: 47.0 / 255, green: 91.0 / 255, blue: 255.0 / 255)
    }

    private func deleteConfirmation(for quote: Quote) -> String {
        let clientName = quote.client.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if clientName.isEmpty {
            return String.localizedStringWithFormat(
                NSLocalizedString("quote.list.delete.confirmation.unnamed", comment: ""),
                quote.number
            )
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("quote.list.delete.confirmation.named", comment: ""),
            quote.number,
            clientName
        )
    }

    private func duplicateNotice(for number: String) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString("quote.list.duplicate.confirmation", comment: ""),
            number
        )
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

struct QuoteRow: View {
    let quote: Quote
    let total: Decimal
    var showsClientName = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                if showsClientName {
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
                }
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
        .accessibilityElement(children: .combine)
    }
}
