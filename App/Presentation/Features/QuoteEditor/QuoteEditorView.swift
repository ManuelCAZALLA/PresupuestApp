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
    private enum AddMode: String, CaseIterable, Identifiable {
        case item
        case kit
        var id: String { rawValue }
    }

    @Bindable var viewModel: QuoteEditorViewModel
    @Environment(AppRouter.self) private var router
    @State private var isPickingItem = false
    @State private var addMode: AddMode = .item

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                quoteOverview
                clientSection
                linesSection
                discountSection
                notesSection
                if let totals = viewModel.totals {
                    CardSurface {
                        TotalsFooter(totals: totals)
                    }
                }
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .background(BrandPalette.background)
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
            .centeredActionWidth(760)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .sheet(isPresented: $isPickingItem) {
            itemPicker
        }
        .onChange(of: isPickingItem) { _, isPresented in
            if isPresented {
                viewModel.refreshCatalog()
            }
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
                Text(verbatim: message)
            }
        }
    }

    private var quoteOverview: some View {
        CardSurface(padding: 18) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(BrandPalette.accent)
                    .frame(width: 48, height: 48)
                    .background(BrandPalette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if viewModel.clientName.isEmpty {
                            Text("quote.client.placeholder")
                        } else {
                            Text(viewModel.clientName)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Spacer(minLength: 0)
                if let quote = viewModel.quote {
                    StatusBadge(status: quote.status)
                }
            }
        }
    }

    private var clientSection: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("quote.editor.client", symbol: "person.crop.circle")
                TextField("field.clientName", text: $viewModel.clientName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                TextField("field.phone", text: $viewModel.clientPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(.roundedBorder)
                TextField("field.address", text: $viewModel.clientAddress)
                    .textContentType(.fullStreetAddress)
                    .textFieldStyle(.roundedBorder)
                TextField("field.workAddress", text: $viewModel.workAddress)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var linesSection: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeading("quote.editor.lines", symbol: "list.bullet.rectangle")
                if viewModel.quote?.lines.isEmpty ?? true {
                    Label("quote.editor.lines.empty", systemImage: "tray")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 70)
                }
                ForEach(viewModel.quote?.lines ?? []) { line in
                    Divider()
                    QuoteLineRow(
                        line: line,
                        total: viewModel.lineTotal(line),
                        onDecrease: { viewModel.decrease(line) },
                        onIncrease: { viewModel.increase(line) },
                        onDelete: { viewModel.delete(line) }
                    )
                }
            }
        }
    }

    private var discountSection: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("quote.editor.discount", symbol: "percent")
                Picker("quote.editor.discount.kind", selection: $viewModel.discountKind) {
                    Text("quote.editor.discount.none").tag(QuoteEditorViewModel.DiscountKind.none)
                    Text("quote.editor.discount.percent").tag(QuoteEditorViewModel.DiscountKind.percent)
                    Text("quote.editor.discount.amount").tag(QuoteEditorViewModel.DiscountKind.amount)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.discountKind) { _, _ in
                    viewModel.persistDetails()
                }
                if viewModel.discountKind != .none {
                    TextField("quote.editor.discount.value", text: $viewModel.discountValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.discountValue) { _, _ in
                            viewModel.persistDetails()
                        }
                }
            }
        }
    }

    private var notesSection: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("quote.editor.notes", symbol: "note.text")
                TextField("quote.editor.notes.placeholder", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func sectionHeading(_ key: LocalizedStringKey, symbol: String) -> some View {
        Label {
            Text(key).font(.headline)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(BrandPalette.accent)
        }
        .padding(.bottom, 2)
    }

    private var itemPicker: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $addMode) {
                    Text("quote.editor.addMode.item").tag(AddMode.item)
                    Text("quote.editor.addMode.kit").tag(AddMode.kit)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Group {
                    if addMode == .item {
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
                        .overlay {
                            if viewModel.filteredCatalog.isEmpty {
                                ContentUnavailableView(
                                    "quote.editor.catalog.empty",
                                    systemImage: "tag",
                                    description: Text("quote.editor.catalog.empty.message")
                                )
                            }
                        }
                    } else {
                        List(viewModel.filteredKits) { kit in
                            Button {
                                viewModel.addKit(kit)
                                isPickingItem = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(kit.name)
                                        .foregroundStyle(.primary)
                                    let detail = viewModel.kitSummary(for: kit)
                                    if !detail.isEmpty {
                                        Text(detail)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .overlay {
                            if viewModel.filteredKits.isEmpty {
                                ContentUnavailableView(
                                    "quote.editor.kits.empty",
                                    systemImage: "square.stack.3d.up",
                                    description: Text("quote.editor.kits.empty.message")
                                )
                            }
                        }
                    }
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
            .onChange(of: isPickingItem) { _, presented in
                if !presented { addMode = .item }
            }
        }
        .adaptiveSheetDetents([.medium, .large])
    }
}

private struct QuoteLineRow: View {
    let line: QuoteLine
    let total: Decimal
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onDelete: () -> Void

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
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("action.delete")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}
