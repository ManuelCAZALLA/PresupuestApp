import SwiftUI
import QuoteCore

struct QuoteEditorScreen: View {
    @State private var viewModel: QuoteEditorViewModel

    init(viewModel: QuoteEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        QuoteEditorView(viewModel: viewModel)
    }
}

/// S5 Editor de presupuesto a mano: cliente, buscador de partidas, +/− y total.
struct QuoteEditorView: View {
    @Bindable var viewModel: QuoteEditorViewModel
    @Environment(AppRouter.self) private var router
    @State private var isPickingItem = false

    var body: some View {
        Form {
            clientSection
            linesSection
            discountSection
            notesSection
            if let totals = viewModel.totals {
                Section {
                    TotalsFooter(totals: totals)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.quote?.number ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.persistDetails()
                    router.openPreview(viewModel.quoteID)
                } label: {
                    Label("quote.editor.pdf", systemImage: "doc.richtext")
                }
                .disabled(viewModel.quote?.lines.isEmpty ?? true)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    isPickingItem = true
                } label: {
                    Label("quote.editor.addItem", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    viewModel.persistDetails()
                    router.openPreview(viewModel.quoteID)
                } label: {
                    Label("quote.editor.send", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.quote?.lines.isEmpty ?? true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .sheet(isPresented: $isPickingItem) {
            itemPicker
        }
        .task { viewModel.load() }
        .onDisappear { viewModel.persistDetails() }
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

    private var clientSection: some View {
        Section("quote.editor.client") {
            TextField("field.clientName", text: $viewModel.clientName)
            TextField("field.phone", text: $viewModel.clientPhone)
                .keyboardType(.phonePad)
            TextField("field.address", text: $viewModel.clientAddress)
            TextField("field.workAddress", text: $viewModel.workAddress)
        }
    }

    private var linesSection: some View {
        Section("quote.editor.lines") {
            if viewModel.quote?.lines.isEmpty ?? true {
                Text("quote.editor.lines.empty")
                    .foregroundStyle(.secondary)
            }
            ForEach(viewModel.quote?.lines ?? []) { line in
                QuoteLineRow(
                    line: line,
                    total: viewModel.lineTotal(line),
                    onDecrease: { viewModel.decrease(line) },
                    onIncrease: { viewModel.increase(line) }
                )
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.delete(line)
                    } label: {
                        Label("action.delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var discountSection: some View {
        Section("quote.editor.discount") {
            Picker("quote.editor.discount.kind", selection: $viewModel.discountKind) {
                Text("quote.editor.discount.none").tag(QuoteEditorViewModel.DiscountKind.none)
                Text("quote.editor.discount.percent").tag(QuoteEditorViewModel.DiscountKind.percent)
                Text("quote.editor.discount.amount").tag(QuoteEditorViewModel.DiscountKind.amount)
            }
            .onChange(of: viewModel.discountKind) { _, _ in
                viewModel.persistDetails()
            }
            if viewModel.discountKind != .none {
                TextField("quote.editor.discount.value", text: $viewModel.discountValue)
                    .keyboardType(.decimalPad)
                    .onChange(of: viewModel.discountValue) { _, _ in
                        viewModel.persistDetails()
                    }
            }
        }
    }

    private var notesSection: some View {
        Section("quote.editor.notes") {
            TextField("quote.editor.notes.placeholder", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var itemPicker: some View {
        NavigationStack {
            List(viewModel.filteredCatalog) { item in
                Button {
                    viewModel.addItem(item)
                    isPickingItem = false
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .foregroundStyle(.primary)
                        HStack {
                            Text(LocalizedStringKey(DomainLabels.measureUnit(item.unit)))
                            Spacer()
                            Text(CurrencyFormatter.string(from: item.unitPrice))
                                .monospacedDigit()
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $viewModel.itemSearch, prompt: "catalog.search")
            .navigationTitle("quote.editor.addItem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { isPickingItem = false }
                }
            }
            .overlay {
                if viewModel.filteredCatalog.isEmpty {
                    ContentUnavailableView(
                        "quote.editor.catalog.empty",
                        systemImage: "tag",
                        description: Text("quote.editor.catalog.empty.message")
                    )
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct QuoteLineRow: View {
    let line: QuoteLine
    let total: Decimal
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(line.name)
                    .font(.body)
                Spacer()
                Text(CurrencyFormatter.string(from: total))
                    .font(.body.weight(.semibold).monospacedDigit())
            }
            HStack {
                Text(LocalizedStringKey(DomainLabels.measureUnit(line.unit)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                QuantityStepper(
                    valueLabel: CurrencyFormatter.plainString(from: line.quantity),
                    accessibilityValue: CurrencyFormatter.plainString(from: line.quantity),
                    onDecrease: onDecrease,
                    onIncrease: onIncrease
                )
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}
